# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
# was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""FlowKit CDR: synthetic call detail records in Flowminder FlowKit's schema, scaled by subscribers x days."""

import argparse
import datetime
from pathlib import Path

from common import db, log
from common.bucket import Bucket
from common.export import Exporter
from common.queries import publish_checked_in

DATASET = "flowkit"
SQL_DIR = Path(__file__).parent / "sql"
FIRST_DATE = datetime.date(2016, 1, 1)  # as in FlowKit's test data

SUBSCRIBERS_PER_SF = 100_000
SUBSCRIBERS_PER_CELL = 100
CELLS_PER_SITE = 3
TACS = 4000
INTERACTIONS = 5  # caller/callee pairs per subscriber
OUT_OF_AREA = 0.05  # share of events away from the subscriber's home cells
RELOCATION = 0.01  # daily chance of moving home
TOPUP_PROBABILITY = 0.1  # daily chance of a topup
# Generated per event table: the legs SQL and events per subscriber and day (None: topups)
EVENTS = {
    "calls": ("pair_legs.sql", 3),
    "sms": ("pair_legs.sql", 4),
    "mds": ("subscriber_legs.sql", 5),
    "topups": ("topup_legs.sql", None),
}
STATIC = ["admin1", "admin2", "admin3", "sites", "cells", "tacs", "cell_region"]
# Measured parquet size of an event row, to generate about one target-size file per chunk
BYTES_PER_ROW = 150


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "tables", nargs="*", default=[*STATIC, *EVENTS],
        help="tables to generate, default all; separate processes can generate different tables in parallel",
    )
    parser.add_argument("--sf", type=int, default=1, help=f"scale factor: {SUBSCRIBERS_PER_SF:,} subscribers each")
    parser.add_argument("--days", type=int, default=31, help="days of events from 2016-01-01, default 31")
    parser.add_argument(
        "--days-per-chunk", type=int,
        help="days generated and sorted together; default from the scale factor, about one parquet file per chunk",
    )


def day_range(first: int, last: int) -> str:
    start, end = FIRST_DATE + datetime.timedelta(first), FIRST_DATE + datetime.timedelta(last)
    return f"{start}" if first == last else f"{start} to {end}"


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    prefix = f"{DATASET}/sf{args.sf}"
    publish_checked_in(bucket, prefix)
    if args.checked_in_only:
        return
    subscribers = args.sf * SUBSCRIBERS_PER_SF
    cells = max(1000, subscribers // SUBSCRIBERS_PER_CELL)
    params = dict(
        SUBSCRIBERS=subscribers, CELLS=cells, SITES=cells // CELLS_PER_SITE, TACS=TACS, DAYS=args.days,
        INTERACTIONS=INTERACTIONS, PAIRS=subscribers * INTERACTIONS, OUT_OF_AREA=OUT_OF_AREA,
        RELOCATION=RELOCATION, TOPUP_PROBABILITY=TOPUP_PROBABILITY,
    )
    # Calls and SMS have two rows per event
    largest = max(per_day * (2 if sql == "pair_legs.sql" else 1) for sql, per_day in EVENTS.values() if per_day) * subscribers
    rows_per_chunk = args.target_mb * 1_000_000 // BYTES_PER_ROW
    days_per_chunk = args.days_per_chunk or max(1, min(args.days, rows_per_chunk // largest))
    chunks = [(first, min(first + days_per_chunk, args.days) - 1) for first in range(0, args.days, days_per_chunk)]
    con = db.connect()
    exporter = Exporter(con, bucket, prefix, args.target_mb, {"days": args.days, "days_per_chunk": days_per_chunk})
    log(f"{prefix}: {subscribers:,} subscribers, {cells:,} cells, {args.days} days")
    for sql in ["setup.sql", "geography.sql", "infrastructure.sql", "subscribers.sql"]:
        db.execute(con, SQL_DIR / sql, **params)
    unknown = set(args.tables) - set(STATIC) - set(EVENTS)
    if unknown:
        raise SystemExit(f"Unknown tables: {', '.join(sorted(unknown))}")
    for table in STATIC:
        if table in args.tables:
            exporter.export(table, table)

    for table, (legs_sql, per_day) in EVENTS.items():
        if table not in args.tables:
            continue
        export = exporter.table(table)
        if export.complete:
            continue
        for first, last in chunks:
            name = day_range(first, last)
            if export.chunk_done(name):
                continue
            log(f"{prefix}/{table}: generating {name}")
            day_params = dict(params, EVENT=table, FIRST_DAY=first, LAST_DAY=last, PER_DAY=subscribers * (per_day or 0))
            for sql in [legs_sql, "locate.sql", f"{table}.sql"]:
                db.execute(con, SQL_DIR / sql, **day_params)
            export.write("_chunk", name, single_chunk=len(chunks) == 1)
            for temp in ["_chunk", "_events", "_legs"]:
                db.drop_table(con, temp)
        export.finish()
