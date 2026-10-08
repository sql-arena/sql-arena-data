"""TPC-DS, generated with dsdgen from the TPC-DS kit (version 2.10)."""

import argparse
import os
import re
import shutil
import subprocess
import sys
import zipfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import duckdb

from common import TEMP_DIR, db, log
from common.bucket import Bucket
from common.download import download, retry
from common.export import Exporter
from common.queries import publish_checked_in, write_queries
from common.staging import Staging

SQL_DIR = Path(__file__).parent / "sql"
KIT_COMMIT = "5a3a81796992b725c2a8b216767e142609966752"
KIT_URL = f"https://github.com/gregrahn/tpcds-kit/archive/{KIT_COMMIT}.zip"
KIT_DIR = Path(os.environ.get("TPCDS_KIT_DIR", TEMP_DIR / "tpcds" / "kit"))  # holds dsdgen and tpcds.idx
# The kit is pre-C99 code that defines the same globals in several files; current compilers reject both by default
KIT_CC = "cc -std=gnu89 -fcommon -Wno-implicit-int -Wno-implicit-function-declaration -Wno-int-conversion"

# dsdgen generates each fact table together with its returns
FACTS = {
    "store_sales": ["store_sales", "store_returns"],
    "catalog_sales": ["catalog_sales", "catalog_returns"],
    "web_sales": ["web_sales", "web_returns"],
    "inventory": ["inventory"],
}
DIMENSIONS = [
    "call_center", "catalog_page", "customer", "customer_address", "customer_demographics", "date_dim",
    "household_demographics", "income_band", "item", "promotion", "reason", "ship_mode", "store", "time_dim",
    "warehouse", "web_page", "web_site",
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
    parser.add_argument("--sf", type=int, default=1, help="scale factor, default 1")
    parser.add_argument(
        "--children", type=int, default=1,
        help="generate the fact tables in this many dsdgen children, to bound memory and disk (100 for SF1000)",
    )
    parser.add_argument("--jobs", type=int, default=4, help="dsdgen children run in parallel, default 4")
    parser.add_argument(
        "--extract-queries", action="store_true",
        help="write the upstream queries to the repo for review and commit, instead of generating data",
    )


def build_kit() -> Path:
    """Build dsdgen from the pinned kit unless KIT_DIR already has it."""
    dsdgen = KIT_DIR / "dsdgen"
    if dsdgen.exists():
        return dsdgen
    work = TEMP_DIR / "tpcds" / "kit-source"
    archive = work / "tpcds-kit.zip"
    retry(lambda: download(KIT_URL, archive))
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(work)
    tools = work / f"tpcds-kit-{KIT_COMMIT}" / "tools"
    log("tpcds: building dsdgen")
    system = "MACOS" if sys.platform == "darwin" else "LINUX"
    subprocess.run(["make", f"OS={system}", f"CC={KIT_CC}", "dsdgen"], cwd=tools, check=True, capture_output=True)
    KIT_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy(tools / "tpcds.idx", KIT_DIR / "tpcds.idx")
    shutil.copy(tools / "dsdgen", dsdgen)
    return dsdgen


def run_dsdgen(work: Path, sf: int, table: str, children: int = 1, child: int = 1) -> None:
    """Generate one table (and its returns) into work. dsdgen truncates long paths, so it runs inside work."""
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)
    shutil.copy(KIT_DIR / "tpcds.idx", work / "tpcds.idx")
    args = [str(KIT_DIR / "dsdgen"), "-SCALE", str(sf), "-TABLE", table, "-DIR", ".", "-DISTRIBUTIONS", "tpcds.idx",
            "-TERMINATE", "N", "-QUIET", "Y", "-FORCE", "Y"]
    if children > 1:
        args += ["-PARALLEL", str(children), "-CHILD", str(child)]
    subprocess.run(args, cwd=work, check=True)


def load(con: duckdb.DuckDBPyConnection, table: str, work: Path) -> None:
    db.execute(con, SQL_DIR / "clear.sql", TABLE=table)
    for path in sorted(work.glob(f"{table}*.dat")):
        if re.fullmatch(rf"{table}(_\d+_\d+)?\.dat", path.name):
            db.execute(con, SQL_DIR / "load.sql", TABLE=table, PATH=path)


def date_bucket(column: str) -> str:
    """About a month of julian date keys per bucket; rows without a date go last."""
    return f"coalesce(lpad(CAST({column} // 30 AS VARCHAR), 6, '0'), '999999')"


def generate_facts(con, exporter: Exporter, args: argparse.Namespace, work: Path, staging: Path) -> None:
    for family, tables in FACTS.items():
        exports = {t: exporter.table(t) for t in tables if not exporter.table(t).complete}
        if not exports:
            continue
        if args.children == 1:
            log(f"{exporter.prefix}: generating {', '.join(tables)}")
            run_dsdgen(work / family, args.sf, family)
            for table in exports:
                load(con, table, work / family)
                exporter.export(table, f"tpcds.{table}", ORDER_BY[table])
            shutil.rmtree(work / family)
            continue

        stagings = {t: Staging(staging / t, date_bucket(ORDER_BY[t]), "date_bucket") for t in exports}
        todo = [c for c in range(1, args.children + 1) if not all(s.staged(c) for s in stagings.values())]
        # Children are generated in parallel batches, then loaded and staged one at a time
        for i in range(0, len(todo), args.jobs):
            batch = todo[i : i + args.jobs]
            log(f"{exporter.prefix}: generating {family} children {batch[0]}-{batch[-1]} of {args.children}")
            with ThreadPoolExecutor(max_workers=args.jobs) as pool:
                list(pool.map(lambda c: run_dsdgen(work / f"{family}_{c}", args.sf, family, args.children, c), batch))
            for child in batch:
                for table, stage in stagings.items():
                    if not stage.staged(child):
                        load(con, table, work / f"{family}_{child}")
                        stage.stage(con, f"tpcds.{table}", child)
                shutil.rmtree(work / f"{family}_{child}")
        for table, export in exports.items():
            stagings[table].export(con, export, ORDER_BY[table])


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    prefix = f"tpcds/sf{args.sf}"
    con = db.connect()
    if args.extract_queries:
        queries = db.fetch_all(con, SQL_DIR / "queries.sql", SF=args.sf)
        write_queries(prefix, set(DIMENSIONS) | set(ORDER_BY), {name: (title, q) for name, title, q in queries})
        return
    publish_checked_in(bucket, prefix)
    if args.checked_in_only:
        return
    exporter = Exporter(con, bucket, prefix, args.target_mb, {"children": args.children})
    build_kit()
    db.execute(con, SQL_DIR / "schema.sql")
    work = TEMP_DIR / prefix / "dsdgen"

    for table in DIMENSIONS:
        if exporter.table(table).complete:
            continue
        run_dsdgen(work / table, args.sf, table)
        load(con, table, work / table)
        exporter.export(table, f"tpcds.{table}")
        db.execute(con, SQL_DIR / "clear.sql", TABLE=table)
        shutil.rmtree(work / table)
    generate_facts(con, exporter, args, work, TEMP_DIR / prefix / "staging")
