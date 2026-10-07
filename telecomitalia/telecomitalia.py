"""Telecom Italia Big Data Challenge: aggregated CDR activity for Milan and Trentino, Nov-Dec 2013."""

import argparse
import functools
import hashlib
import json
import os
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

import duckdb

from common import TEMP_DIR, db, log
from common.bucket import Bucket, session
from common.download import USER_AGENT, download, retry
from common.export import Exporter
from common.queries import publish_checked_in

DATASET = "telecomitalia"
DATAVERSE = "https://dataverse.harvard.edu"
SQL_DIR = Path(__file__).parent / "sql"
WORK_DIR = TEMP_DIR / DATASET / "source"

# Where the token lives when DATAVERSE_API_TOKEN is not set, e.g. on EC2
TOKEN_PARAMETER = os.environ.get("DATAVERSE_TOKEN_PARAMETER", "/sql-arena/dataverse-api-token")
TOKEN_REGION = os.environ.get("DATAVERSE_TOKEN_REGION", "eu-north-1")

# Cut off mid-line at the source (its md5 matches Dataverse); the partial last line is skipped
TRUNCATED_FILES = {"tn-to-provinces-2013-11-18.txt"}


@dataclass(frozen=True)
class Table:
    name: str
    doi: str
    sql_file: str  # loads a list of source files into _chunk, sorted


TABLES = {
    t.name: t
    for t in [
        Table("grid_mi", "10.7910/DVN/QJWLFU", "grid.sql"),
        Table("grid_tn", "10.7910/DVN/FZRVSX", "grid.sql"),
        Table("sms_call_internet_mi", "10.7910/DVN/EGZHFV", "activity.sql"),
        Table("sms_call_internet_tn", "10.7910/DVN/QLCABU", "activity.sql"),
        Table("mi_to_provinces", "10.7910/DVN/F3RBMF", "provinces.sql"),
        Table("tn_to_provinces", "10.7910/DVN/MAW5AR", "provinces.sql"),
        Table("mi_to_mi", "10.7910/DVN/JZMTBJ", "flows.sql"),
        Table("tn_to_tn", "10.7910/DVN/KCRS61", "flows.sql"),
    ]
}


@dataclass(frozen=True)
class SourceFile:
    id: int
    name: str
    size: int
    md5: str


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("tables", nargs="*", default=list(TABLES), help="tables to generate, default all")
    parser.add_argument(
        "--chunk-gb", type=float, default=8,
        help="source GB of consecutive daily files loaded and sorted together, default 8",
    )
    parser.add_argument("--until", help="last day to generate (YYYY-MM-DD), default all; for partial runs and tests")
    parser.add_argument("--downloads", type=int, default=4, help="parallel downloads, default 4")


@functools.cache
def dataverse_token() -> str:
    """DATAVERSE_API_TOKEN, or else the SecureString SSM parameter TOKEN_PARAMETER."""
    if token := os.environ.get("DATAVERSE_API_TOKEN"):
        return token
    ssm = session().client("ssm", region_name=TOKEN_REGION)
    return ssm.get_parameter(Name=TOKEN_PARAMETER, WithDecryption=True)["Parameter"]["Value"]


def api(path: str, data: bytes | None = None) -> dict:
    headers = {"User-Agent": USER_AGENT, "Content-Type": "application/json"}
    if data is not None:
        headers["X-Dataverse-key"] = dataverse_token()
    request = urllib.request.Request(f"{DATAVERSE}{path}", data=data, headers=headers)
    with urllib.request.urlopen(request, timeout=120) as response:
        return json.load(response)["data"]


def list_files(doi: str) -> list[SourceFile]:
    version = retry(lambda: api(f"/api/datasets/:persistentId/?persistentId=doi:{doi}"))["latestVersion"]
    files = [
        SourceFile(d["id"], d["filename"], d["filesize"], d["md5"]) for d in (f["dataFile"] for f in version["files"])
    ]
    return sorted(files, key=lambda f: f.name)


def fetch(file: SourceFile) -> Path:
    """Download a file through the guestbook: each attempt gets a fresh signed URL, valid for a few minutes."""
    path = WORK_DIR / file.name

    def attempt() -> None:
        url = api(f"/api/access/datafile/{file.id}?signed=true", b'{"guestbookResponse": {}}')["signedUrl"]
        download(url, path)
        md5 = hashlib.md5()
        with open(path, "rb") as f:
            while block := f.read(8 << 20):
                md5.update(block)
        if md5.hexdigest() != file.md5:
            path.unlink()
            raise ConnectionError(f"{file.name}: md5 does not match Dataverse")

    if not path.exists():
        log(f"{DATASET}: downloading {file.name} ({file.size / 1e9:.1f} GB)")
        retry(attempt)
    return path


def chunks(files: list[SourceFile], chunk_bytes: float) -> list[list[SourceFile]]:
    """Consecutive files grouped up to chunk_bytes of source each."""
    result: list[list[SourceFile]] = []
    for file in files:
        if result and sum(f.size for f in result[-1]) + file.size <= chunk_bytes:
            result[-1].append(file)
        else:
            result.append([file])
    return result


def last_day(files: list[SourceFile]) -> str:
    """The date in the name of the last daily file, e.g. MItoMI-2013-11-01.txt; grids have none."""
    stem = Path(files[-1].name).stem
    return stem[-10:] if stem[-10:-6].isdigit() else ""


def chunk_name(files: list[SourceFile]) -> str:
    return files[0].name if len(files) == 1 else f"{files[0].name} to {files[-1].name}"


def check_rejects(con: duckdb.DuckDBPyConnection) -> None:
    """Fail on any line read_csv rejected, except the one partial line of a known truncated file."""
    rejects = db.fetch_all(con, SQL_DIR / "rejects.sql")
    names = [Path(path).name for path, _, _ in rejects]
    unexpected = [r for r, name in zip(rejects, names) if name not in TRUNCATED_FILES or names.count(name) > 1]
    if unexpected:
        raise SystemExit("Rejected source lines:\n" + "\n".join(f"  {p} line {line}: {e}" for p, line, e in unexpected))
    for name, (_, line, _) in zip(names, rejects):
        log(f"{DATASET}: skipped the truncated line {line} of {name}")


def generate_table(con: duckdb.DuckDBPyConnection, exporter: Exporter, table: Table, args: argparse.Namespace) -> None:
    export = exporter.table(table.name)
    if export.complete:
        return
    all_chunks = chunks(list_files(table.doi), args.chunk_gb * 1e9)
    todo = [c for c in all_chunks if not export.chunk_done(chunk_name(c))]
    remaining = len(todo)
    todo = [c for c in todo if not args.until or last_day(c) <= args.until]
    downloads = ThreadPoolExecutor(max_workers=args.downloads)

    def fetch_all(files: list[SourceFile]) -> list[Path]:
        return list(downloads.map(fetch, files))

    # The next chunk is downloaded while the current one is loaded and exported
    with ThreadPoolExecutor(max_workers=1) as prefetch:
        next_paths = prefetch.submit(fetch_all, todo[0]) if todo else None
        for i, files in enumerate(todo):
            paths = next_paths.result()
            if i + 1 < len(todo):
                next_paths = prefetch.submit(fetch_all, todo[i + 1])
            log(f"{DATASET}/{table.name}: loading {chunk_name(files)}")
            db.execute(con, SQL_DIR / table.sql_file, PATHS=[str(p) for p in paths])
            if table.sql_file != "grid.sql":
                check_rejects(con)
            export.write("_chunk", chunk_name(files), single_chunk=len(all_chunks) == 1)
            db.drop_table(con, "_chunk")
            for path in paths:
                path.unlink()
    downloads.shutdown()
    if len(todo) == remaining:
        export.finish()
    else:
        log(f"{DATASET}/{table.name}: stopped at {args.until}, {remaining - len(todo)} chunks left")


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    unknown = set(args.tables) - set(TABLES)
    if unknown:
        raise SystemExit(f"Unknown tables: {', '.join(sorted(unknown))}")
    dataverse_token()
    publish_checked_in(bucket, DATASET)
    con = db.connect()
    exporter = Exporter(con, bucket, DATASET, args.target_mb, {"chunk_gb": args.chunk_gb})
    for name in args.tables:
        generate_table(con, exporter, TABLES[name], args)
