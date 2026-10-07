"""TPC-H, generated with the DuckDB tpch extension."""

import argparse
import shutil
from pathlib import Path

from common import TEMP_DIR, db, log
from common.bucket import Bucket
from common.export import Exporter, TableExport
from common.queries import publish_checked_in, write_queries

SQL_DIR = Path(__file__).parent / "sql"
BASE_TABLES = ["customer", "nation", "part", "region", "supplier"]
STEP_TABLES = ["lineitem", "orders", "partsupp"]
ORDER_BY = {"lineitem": "l_shipdate", "orders": "o_orderdate"}


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--sf", type=float, default=1, help="scale factor, default 1")
    parser.add_argument(
        "--children", type=int, default=1,
        help="generate lineitem, orders and partsupp in this many dbgen steps, to bound memory (100 for SF1000)",
    )
    parser.add_argument("--steps", help="FIRST-LAST range of steps to generate, default all")
    parser.add_argument(
        "--extract-queries", action="store_true",
        help="write the upstream queries to the repo for review and commit, instead of generating data",
    )


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    prefix = f"tpch/sf{args.sf:g}"
    con = db.connect()
    if args.extract_queries:
        queries = db.fetch_all(con, SQL_DIR / "queries.sql", SF=args.sf)
        write_queries(prefix, set(BASE_TABLES + STEP_TABLES), {name: (title, q) for name, title, q in queries})
        return
    publish_checked_in(bucket, prefix)
    exporter = Exporter(con, bucket, prefix, args.target_mb)

    tables = BASE_TABLES + (STEP_TABLES if args.children == 1 else [])
    missing = [t for t in tables if not exporter.table(t).complete]
    if missing:
        log(f"{prefix}: generating {', '.join(missing)}")
        db.execute(con, SQL_DIR / "dbgen.sql", SF=args.sf)
        for table in missing:
            exporter.export(table, f"tpch.{table}", ORDER_BY.get(table))
    if args.children > 1:
        generate_steps(con, exporter, args, TEMP_DIR / prefix / "staging")


def generate_steps(con, exporter: Exporter, args: argparse.Namespace, staging: Path) -> None:
    """lineitem and orders are staged locally per month over all steps, then sorted and exported a month at a time.

    partsupp has no date, so each step is exported directly.
    """
    partsupp = exporter.table("partsupp")
    ordered = {t: exporter.table(t) for t in ORDER_BY}
    ordered = {t: e for t, e in ordered.items() if not e.complete}
    first, last = map(int, args.steps.split("-")) if args.steps else (0, args.children - 1)

    def step_chunk(step: int) -> str:
        return f"step {step} of {args.children}"

    def staged(table: str, step: int) -> Path:
        return staging / table / f"_staged_{step:04}"

    for step in range(first, last + 1):
        to_stage = [t for t in ordered if not staged(t, step).exists()]
        if partsupp.chunk_done(step_chunk(step)) and not to_stage:
            continue
        log(f"{exporter.prefix}: generating {step_chunk(step)}")
        db.execute(con, SQL_DIR / "dbgen_step.sql", SF=args.sf, CHILDREN=args.children, STEP=step)
        partsupp.write("tpch.partsupp", step_chunk(step), single_chunk=False)
        for table in to_stage:
            (staging / table).mkdir(parents=True, exist_ok=True)
            for partial in (staging / table).glob(f"*/step_{step}_*.parquet"):
                partial.unlink()
            db.execute(con, SQL_DIR / "stage.sql", TABLE=table, ORDER_BY=ORDER_BY[table], DIR=staging / table, STEP=step)
            staged(table, step).touch()

    if all(partsupp.chunk_done(step_chunk(s)) for s in range(args.children)):
        partsupp.finish()
    for table, export in ordered.items():
        if all(staged(table, s).exists() for s in range(args.children)):
            export_staged(con, export, ORDER_BY[table], staging / table)
        else:
            log(f"{exporter.prefix}/{table}: not all steps staged yet, run the remaining steps on this machine")


def export_staged(con, export: TableExport, order_by: str, staging: Path) -> None:
    for month_dir in sorted(staging.glob("_month=*")):
        chunk = f"month {month_dir.name.removeprefix('_month=')}"
        if export.chunk_done(chunk):
            continue
        db.execute(con, SQL_DIR / "staged_month.sql", DIR=month_dir)
        export.write("_month", chunk, single_chunk=False, order_by=order_by)
        db.drop_table(con, "_month")
    export.finish()
    shutil.rmtree(staging)
