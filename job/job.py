"""Join Order Benchmark: the IMDB snapshot published with the JOB queries."""

import argparse
import re
import tarfile
import zipfile
from pathlib import Path

from common import TEMP_DIR, db, log
from common.bucket import Bucket
from common.download import download, retry
from common.export import Exporter
from common.queries import publish_checked_in, write_queries

SOURCE_URL = "https://event.cwi.nl/da/job/imdb.tgz"
QUERIES_COMMIT = "a39603662e023e449cb2121997a5034df9e02ebf"
QUERIES_URL = f"https://github.com/gregrahn/join-order-benchmark/archive/{QUERIES_COMMIT}.zip"
SQL_DIR = Path(__file__).parent / "sql"
WORK_DIR = TEMP_DIR / "job" / "source"
ORDER_BY = {"aka_title": "production_year", "title": "production_year"}


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--extract-queries", action="store_true",
        help="write the upstream queries to the repo for review and commit, instead of generating data",
    )


def extract(archive: Path, name: str) -> Path:
    path = WORK_DIR / name
    if not path.exists():
        with tarfile.open(archive) as tar:
            tar.extract(name, WORK_DIR, filter="data")
    return path


def extract_queries() -> None:
    """Write the 113 benchmark queries (1a to 33c) from the join-order-benchmark repository to the repo."""
    repo = WORK_DIR / "join-order-benchmark.zip"
    retry(lambda: download(QUERIES_URL, repo))
    with zipfile.ZipFile(repo) as zf:
        files = {Path(n).stem: zf.read(n).decode() for n in zf.namelist() if n.count("/") == 1 and n.endswith(".sql")}
    con = db.connect()
    db.execute(con, SQL_DIR / "schema.sql", SCHEMA_SQL=files["schema"])
    # 15a-15d alias aka_title as at, which DuckDB parses as a keyword; quoting it is valid in every dialect
    queries = {
        name: (f"JOB {name}", re.sub(r"\bat\b(?=[,.\s])", '"at"', sql) if name.startswith("15") else sql)
        for name, sql in sorted(files.items())
        if name[0].isdigit()
    }
    write_queries("job", set(db.tables(con, "job")), queries)


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    if args.extract_queries:
        extract_queries()
        return
    publish_checked_in(bucket, "job")
    if args.checked_in_only:
        return

    archive = WORK_DIR / "imdb.tgz"
    if not archive.exists():
        log(f"job: downloading {SOURCE_URL}")
        retry(lambda: download(SOURCE_URL, archive))

    con = db.connect()
    db.execute(con, SQL_DIR / "schema.sql", SCHEMA_SQL=extract(archive, "schematext.sql").read_text())
    exporter = Exporter(con, bucket, "job", args.target_mb)
    for table in db.tables(con, "job"):
        if exporter.table(table).complete:
            continue
        source = extract(archive, f"{table}.csv")
        db.execute(con, SQL_DIR / "load.sql", TABLE=table, PATH=source)
        exporter.export(table, f"job.{table}", ORDER_BY.get(table))
        db.drop_table(con, f"job.{table}")
        source.unlink()
