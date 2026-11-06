"""Agentic telemetry: synthetic OpenTelemetry-style traces of LLM agents over one year, with dates that matter."""

import argparse
import datetime
from pathlib import Path

from common import db, log
from common.bucket import Bucket
from common.export import Exporter
from common.queries import publish_checked_in

DATASET = "agenttelemetry"
SQL_DIR = Path(__file__).parent / "sql"
FIRST_DATE = datetime.date(2025, 1, 1)
DAYS = 365

SESSIONS_PER_DAY = 180  # at SF 1 on a weekday in mid-year, about 100,000 traces a year
USERS_PER_SF = 20_000
TENANTS = 200
# Relative share of a day's sessions in each hour from midnight UTC, busiest when Europe and America overlap
HOUR_WEIGHTS = [2.0, 1.5, 1.2, 1.0, 1.0, 1.2, 2.0, 3.0, 4.5, 5.5, 6.0, 6.5, 6.5, 7.0, 7.5, 7.5, 7.0, 6.5, 5.5, 4.5,
                3.5, 3.0, 2.5, 2.2]
DIMENSIONS = ["tenants", "model_prices"]
FACTS = ["spans", "traces", "scores"]
# Measured parquet size of the spans of a session, to generate about one target-size spans file per chunk
BYTES_PER_SESSION = 14_000


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("tables", nargs="*", default=DIMENSIONS + FACTS, help="tables to generate, default all")
    parser.add_argument("--sf", type=int, default=1, help="scale factor: about 100,000 agent runs a year each")
    parser.add_argument("--days", type=int, default=DAYS, help=f"days from {FIRST_DATE}, default {DAYS}; fewer for tests")
    parser.add_argument("--parquet-only", action="store_true", help="no csv.zip copies, for large scale factors")
    parser.add_argument("--shard", type=shard, help="K/N: generate every N-th chunk from chunk K, to run N at once")
    parser.add_argument("--merge-shards", type=int, metavar="N",
                        help="combine the manifests of N complete shards, instead of generating")


def shard(value: str) -> tuple[int, int]:
    k, n = (int(x) for x in value.split("/"))
    if not 0 <= k < n:
        raise argparse.ArgumentTypeError("K/N needs 0 <= K < N")
    return k, n


def day_chunks(sessions: list[float], per_chunk: float) -> list[tuple[int, int]]:
    """Consecutive days grouped to about per_chunk sessions each."""
    chunks, first, total = [], 0, 0.0
    for day, n in enumerate(sessions):
        total += n
        if total >= per_chunk or day == len(sessions) - 1:
            chunks.append((first, day))
            first, total = day + 1, 0.0
    return chunks


def day_range(first: int, last: int) -> str:
    return f"{FIRST_DATE + datetime.timedelta(days=first)} to {FIRST_DATE + datetime.timedelta(days=last)}"


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    unknown = set(args.tables) - set(DIMENSIONS) - set(FACTS)
    if unknown:
        raise SystemExit(f"Unknown tables: {', '.join(sorted(unknown))}")
    if not 1 <= args.days <= DAYS:
        raise SystemExit(f"--days must be 1 to {DAYS}")
    prefix = f"{DATASET}/sf{args.sf}"
    first_shard = args.shard is None or args.shard[0] == 0
    if first_shard:
        publish_checked_in(bucket, prefix)
    if args.checked_in_only:
        return
    params = dict(
        SF=args.sf, DAYS=args.days, FIRST_DATE=FIRST_DATE, SESSIONS_PER_DAY=SESSIONS_PER_DAY, TENANTS=TENANTS,
        USERS=args.sf * USERS_PER_SF, HOUR_WEIGHTS=HOUR_WEIGHTS,
    )
    con = db.connect()
    db.execute(con, SQL_DIR / "setup.sql", **params)
    settings = {"days": args.days} | ({"csv": False} if args.parquet_only else {})
    csv = not args.parquet_only
    exporter = Exporter(con, bucket, prefix, args.target_mb, settings, csv=csv)

    if args.merge_shards:
        pending = [t for t in FACTS if t in args.tables and not exporter.table(t).merge_shards(args.merge_shards)]
        if pending:
            raise SystemExit(f"{prefix}: shards of {', '.join(pending)} are not all complete yet")
        return

    if first_shard:
        db.execute(con, SQL_DIR / "dimensions.sql")
        for table in DIMENSIONS:
            if table in args.tables:
                exporter.export(table, f"_export_{table}")

    shard_exporter = Exporter(con, bucket, prefix, args.target_mb, settings, csv=csv, shard=args.shard)
    exports = {t: shard_exporter.table(t) for t in FACTS if t in args.tables}
    exports = {t: e for t, e in exports.items() if not e.complete}
    sessions = [n for (n,) in db.fetch_all(con, SQL_DIR / "days.sql", **params)]
    chunks = day_chunks(sessions, args.target_mb * 1_000_000 / BYTES_PER_SESSION)
    log(f"{prefix}: about {sum(sessions):,.0f} sessions in {args.days} days, {len(chunks)} chunks")
    # Shards take every n-th chunk, so each gets busy and quiet days alike. Their parts are named by the chunk's
    # first day, which keeps file names in time order.
    k, n = args.shard or (0, 1)
    for first, last in chunks[k::n]:
        name = day_range(first, last)
        if all(e.chunk_done(name) for e in exports.values()):
            continue
        log(f"{prefix}: generating {name}")
        for sql in ["traces.sql", "spans.sql", "scores.sql", "export.sql"]:
            db.execute(con, SQL_DIR / sql, **params, FIRST_DAY=first, LAST_DAY=last)
        for table, export in exports.items():
            stem = f"{table}_{first:03}" if args.shard else None
            export.write(f"_export_{table}", name, single_chunk=len(chunks) == 1, stem=stem)
    for export in exports.values():
        export.finish()
