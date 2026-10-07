"""TPC-DS, generated with the DuckDB tpcds extension."""

import argparse
from pathlib import Path

from common import db, log
from common.bucket import Bucket
from common.export import Exporter
from common.queries import publish_checked_in, write_queries

SQL_DIR = Path(__file__).parent / "sql"
TABLES = [
    "call_center", "catalog_page", "catalog_returns", "catalog_sales", "customer", "customer_address",
    "customer_demographics", "date_dim", "household_demographics", "income_band", "inventory", "item",
    "promotion", "reason", "ship_mode", "store", "store_returns", "store_sales", "time_dim", "warehouse",
    "web_page", "web_returns", "web_sales", "web_site",
]
ORDER_BY = {
    "catalog_returns": "cr_returned_date_sk",
    "catalog_sales": "cs_sold_date_sk",
    "inventory": "inv_date_sk",
    "store_returns": "sr_returned_date_sk",
    "store_sales": "ss_sold_date_sk",
    "web_returns": "wr_returned_date_sk",
    "web_sales": "ws_sold_date_sk",
}


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--sf", type=float, default=1, help="scale factor, default 1")
    parser.add_argument(
        "--extract-queries", action="store_true",
        help="write the upstream queries to the repo for review and commit, instead of generating data",
    )


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    prefix = f"tpcds/sf{args.sf:g}"
    con = db.connect()
    if args.extract_queries:
        queries = db.fetch_all(con, SQL_DIR / "queries.sql")
        write_queries(prefix, set(TABLES), {name: (title, q) for name, title, q in queries})
        return
    publish_checked_in(bucket, prefix)
    exporter = Exporter(con, bucket, prefix, args.target_mb)
    missing = [t for t in TABLES if not exporter.table(t).complete]
    if not missing:
        return
    log(f"{prefix}: generating {', '.join(missing)}")
    db.execute(con, SQL_DIR / "dsdgen.sql", SF=args.sf)
    for table in missing:
        exporter.export(table, f"tpcds.{table}", ORDER_BY.get(table))
