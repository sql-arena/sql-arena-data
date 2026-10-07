"""TPC-H, generated with the DuckDB tpch extension."""

import argparse
from pathlib import Path

from common import TEMP_DIR, db, log
from common.bucket import Bucket
from common.export import Exporter
from common.queries import publish_checked_in, write_queries
from common.staging import Staging

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
    exporter = Exporter(con, bucket, prefix, args.target_mb, {"children": args.children})

    if args.children == 1:
        missing = [t for t in BASE_TABLES + STEP_TABLES if not exporter.table(t).complete]
        if missing:
            log(f"{prefix}: generating {', '.join(missing)}")
            db.execute(con, SQL_DIR / "dbgen.sql", SF=args.sf)
            for table in missing:
                exporter.export(table, f"tpch.{table}", ORDER_BY.get(table))
    else:
        generate_steps(con, exporter, args, TEMP_DIR / prefix / "staging")


def generate_steps(con, exporter: Exporter, args: argparse.Namespace, staging: Path) -> None:
    """Every table is generated in dbgen steps; the union of the steps is the full table.

    partsupp is exported per step. lineitem and orders are staged locally per month, then sorted and exported a
    month at a time. The small tables are staged whole and exported once all steps are staged, so they get
    full-size parts.
    """
    partsupp = exporter.table("partsupp")
    staged_tables = {t: exporter.table(t) for t in [*ORDER_BY, *BASE_TABLES]}
    staged_tables = {t: e for t, e in staged_tables.items() if not e.complete}
    stagings = {
        t: Staging(staging / t, f"strftime({ORDER_BY[t]}, '%Y-%m')", "month") if t in ORDER_BY
        else Staging(staging / t, "'all'", "table")
        for t in staged_tables
    }
    first, last = map(int, args.steps.split("-")) if args.steps else (0, args.children - 1)

    def step_chunk(step: int) -> str:
        return f"step {step} of {args.children}"

    for step in range(first, last + 1):
        to_stage = [t for t, s in stagings.items() if not s.staged(step)]
        if partsupp.chunk_done(step_chunk(step)) and not to_stage:
            continue
        log(f"{exporter.prefix}: generating {step_chunk(step)}")
        db.execute(con, SQL_DIR / "dbgen_step.sql", SF=args.sf, CHILDREN=args.children, STEP=step)
        partsupp.write("tpch.partsupp", step_chunk(step), single_chunk=False)
        for table in to_stage:
            stagings[table].stage(con, f"tpch.{table}", step)

    if all(partsupp.chunk_done(step_chunk(s)) for s in range(args.children)):
        partsupp.finish()
    for table, export in staged_tables.items():
        if all(stagings[table].staged(s) for s in range(args.children)):
            stagings[table].export(con, export, ORDER_BY.get(table))
        else:
            log(f"{exporter.prefix}/{table}: not all steps staged yet, run the remaining steps on this machine")
