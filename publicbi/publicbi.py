"""Public BI Benchmark: real Tableau Public workbooks and the queries Tableau ran against them."""

import argparse
import bz2
import shutil
import zipfile
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

import duckdb

from common import TEMP_DIR, db, log
from common.bucket import Bucket
from common.download import download, retry
from common.export import Exporter
from common.queries import publish_checked_in, query_dir, write_queries

DATASET = "publicbi"
REPO_COMMIT = "cf9909083bf9ed185cd7f5121a2881e1fea0e7a9"
REPO_URL = f"https://github.com/cwida/public_bi_benchmark/archive/{REPO_COMMIT}.zip"
SQL_DIR = Path(__file__).parent / "sql"
WORK_DIR = TEMP_DIR / DATASET / "source"
BENCHMARK_DIR = WORK_DIR / f"public_bi_benchmark-{REPO_COMMIT}" / "benchmark"


@dataclass(frozen=True)
class Table:
    name: str
    schema: str  # CREATE TABLE statement from the benchmark repository
    url: str


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("workbooks", nargs="*", help="workbooks to generate, e.g. Arade CMSprovider; default all")
    parser.add_argument(
        "--extract-queries", action="store_true",
        help="write the upstream queries to the repo for review and commit, instead of generating data",
    )


def read_workbooks() -> dict[str, list[Table]]:
    workbooks = {}
    for urls in sorted(BENCHMARK_DIR.glob("*/data-urls.txt")):
        tables = []
        for url in urls.read_text().split():
            name = url.rsplit("/", 1)[-1].removesuffix(".csv.bz2")
            schema = (urls.parent / "tables" / f"{name}.table.sql").read_text()
            tables.append(Table(name, schema, url.replace("http://", "https://", 1)))
        workbooks[urls.parent.name] = tables
    return workbooks


def fetch_source(table: Table) -> Path:
    """Download and decompress the source csv of a table."""
    archive = WORK_DIR / f"{table.name}.csv.bz2"
    csv = WORK_DIR / f"{table.name}.csv"
    if not csv.exists():
        log(f"{DATASET}/{table.name}: downloading and decompressing")
        retry(lambda: download(table.url, archive))
        tmp = csv.with_suffix(".csv.tmp")
        with bz2.open(archive) as src, open(tmp, "wb") as out:
            shutil.copyfileobj(src, out, length=8 << 20)
        tmp.rename(csv)
    archive.unlink(missing_ok=True)
    return csv


def export_table(con: duckdb.DuckDBPyConnection, exporter: Exporter, table: Table, csv: Path) -> None:
    db.execute(con, SQL_DIR / "create.sql", TABLE=table.name, SCHEMA_SQL=table.schema)
    order_by = (db.fetch_all(con, SQL_DIR / "order_column.sql", TABLE=table.name) or [(None,)])[0][0]
    columns = db.fetch_value(con, SQL_DIR / "column_count.sql", TABLE=table.name)
    fields = ", ".join(f"f[{i}]" for i in range(1, columns + 1))
    db.execute(con, SQL_DIR / "load.sql", TABLE=table.name, PATH=csv, FIELDS=fields, COLUMN_COUNT=columns)
    exporter.export(table.name, f'"{table.name}"', order_by)
    db.drop_table(con, f'"{table.name}"')


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    repo = WORK_DIR / "public_bi_benchmark.zip"
    retry(lambda: download(REPO_URL, repo))
    if not BENCHMARK_DIR.exists():
        with zipfile.ZipFile(repo) as zf:
            zf.extractall(WORK_DIR)
    workbooks = read_workbooks()
    unknown = set(args.workbooks) - set(workbooks)
    if unknown:
        raise SystemExit(f"Unknown workbooks: {', '.join(sorted(unknown))}")

    con = db.connect()
    if args.extract_queries:
        tables = {t.name for ts in workbooks.values() for t in ts}
        queries = db.fetch_all(con, SQL_DIR / "queries.sql", DIR=BENCHMARK_DIR)
        write_queries(DATASET, tables, {name: (title, q) for name, title, q in queries})
        return
    publish_checked_in(bucket, DATASET)
    if args.checked_in_only:
        return
    db.execute(con, SQL_DIR / "load_queries.sql", DIR=query_dir(DATASET))
    exporter = Exporter(con, bucket, DATASET, args.target_mb)
    todo = [t for w in args.workbooks or workbooks for t in workbooks[w] if not exporter.table(t.name).complete]
    log(f"{DATASET}: {len(todo)} tables to generate")

    # The next table is downloaded and decompressed while the current one is exported
    with ThreadPoolExecutor(max_workers=1) as prefetch:
        next_source = prefetch.submit(fetch_source, todo[0]) if todo else None
        for i, table in enumerate(todo):
            csv = next_source.result()
            if i + 1 < len(todo):
                next_source = prefetch.submit(fetch_source, todo[i + 1])
            export_table(con, exporter, table, csv)
            csv.unlink()
