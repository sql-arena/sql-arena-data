"""Agent telemetry generated into Amazon S3 Tables, for the demo app in agenttelemetry/demo.

Run from the repo root with AWS credentials for the account:

    uv run python -m agenttelemetry.s3tables plan --sf 10 --out plan.json
    uv run python -m agenttelemetry.s3tables work --coordinator http://127.0.0.1:8080 [--processes N]
    uv run python -m agenttelemetry.s3tables commit < requests.jsonl
    uv run python -m agenttelemetry.s3tables maintenance --sf 10
    uv run python -m agenttelemetry.s3tables validate --sf 10

plan creates the table bucket, namespace agenttelemetry_sf<N> and its tables if missing, loads the dimensions, and
writes the chunks of the fact tables: slices of at most --sessions-per-chunk sessions of one day. The coordinator (the
demo web app) runs it, then hands the chunks out to workers.

work runs processes that each ask the coordinator for a chunk, generate it, write each fact table of it as parquet
files into the table's storage, one per day partition, and tell the coordinator. The coordinator runs commit, which
appends the files it is told of to the tables in one commit per table, without reading them (iceberg_append.py).
The tables are Iceberg v3, with the JSON text of spans as VARIANT.

validate measures the loaded data through DuckDB and compares it with the claims of agenttelemetry/README.md.
"""

import argparse
import datetime
import json
import multiprocessing
import os
import re
import socket
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import boto3
import duckdb

from agenttelemetry import agenttelemetry as at
from agenttelemetry import iceberg_append as ia
from common import TEMP_DIR, db, log

REGION = os.environ.get("AWS_REGION", "us-east-1")
TABLE_BUCKET = os.environ.get("TABLE_BUCKET", "sql-arena-agenttelemetry")
TARGET_FILE_MB = 512
# Fact tables are partitioned by the day of their time column, and compaction z-orders the ids within a day
TIME_COLUMNS = {"spans": "start_time", "traces": "start_time", "scores": "created_at"}
ZORDER = ["trace_id", "session_id"]
ATTACH_SQL = Path(__file__).parent / "demo" / "web" / "src" / "lib" / "server" / "sql" / "attach.sql"
# The slice of a day from session 0 holds the day's needles only if it has the sessions that hold them at SF 1
MIN_SESSIONS_PER_CHUNK = 1_000
# About 45,000 spans, which one process generates in under PROCESS_MEMORY without spilling
SESSIONS_PER_CHUNK = 2_500
# Each worker process has one DuckDB thread and this much memory, so one runs per core
PROCESS_MEMORY = "2GB"
POLL_SECONDS = 10
EPOCH = datetime.date(1970, 1, 1)
COMMIT_ATTEMPTS = 5

ICEBERG_TYPES = {"VARCHAR": "string", "INTEGER": "int", "BIGINT": "long", "DOUBLE": "double", "BOOLEAN": "boolean",
                 "DATE": "date", "TIMESTAMP WITH TIME ZONE": "timestamptz", "VARIANT": "variant"}

# Claims of the README, at SF1 for those that grow with the scale factor; (low, high) for a range
SESSIONS_SF1 = 55_785
EXPECTED = {
    "rows tenants": 200, "rows model_prices": 10,
    "share of traces in tenant 1 %": (21.5, 23),
    "share of sessions support-agent %": (31.5, 33.5), "share of sessions coding-agent %": (21.5, 23.5),
    "share of sessions research-agent %": (17.5, 18.5), "share of sessions sre-agent %": (13.5, 14.5),
    "share of sessions data-agent %": (12.5, 13.5),
    "share of spans in the last 7 days %": (2.4, 2.95), "share of spans in the last quarter %": (28, 35),
    "share of spans in Q16 hour %": (0.035, 0.055),
    "needle sessions 0-39 of each day found": 365 * 40, "needle traces of sessions 0-39 found": 365 * 40,
    "needle codes in exactly 2 spans": 365 * 4, "needle places in exactly 2 spans on their day": 365,
    "other planted places": 0, "Q10 key rows": 2, "Q11 ERR_LEDGER_SHARD_7731 rows": 14, "Q13 Ærøskøbing rows": 2,
}
SCALED = {"rows spans": 991_998, "rows traces": 99_016, "rows scores": 70_231,
          "distinct traces.session_id": SESSIONS_SF1}
# Sessions per day are rounded at every scale factor, so these do not scale exactly
BY_SF = {"support sessions on Black Friday": {1: 450, 10: 4_604},
         "support sessions the Friday before": {1: 68, 10: 769},
         "distinct traces.user_id": {1: 18_007, 10: 62_943}}


def namespace(sf: int) -> str:
    return f"agenttelemetry_sf{sf}"


def table_bucket_arn() -> str:
    """The table bucket, created if missing."""
    client = boto3.client("s3tables", region_name=REGION)
    for page in client.get_paginator("list_table_buckets").paginate(prefix=TABLE_BUCKET):
        for bucket in page["tableBuckets"]:
            if bucket["name"] == TABLE_BUCKET:
                return bucket["arn"]
    log(f"creating table bucket {TABLE_BUCKET} in {REGION}")
    return client.create_table_bucket(name=TABLE_BUCKET)["arn"]


def connect(arn: str, temp_dir: Path = TEMP_DIR / "duckdb_tmp") -> duckdb.DuckDBPyConnection:
    """A DuckDB connection with the table bucket attached as catalog s3tables.

    DuckDB does not sort what it inserts by a table's sort order; the facts are declared sorted for compaction,
    which z-orders by it.
    """
    con = db.connect(temp_dir=temp_dir)
    db.execute(con, ATTACH_SQL, TABLE_BUCKET_ARN=arn, REGION=REGION)
    con.execute("SET unsafe_iceberg_ignore_sort_order = true")
    con.execute("SET enable_progress_bar = false")
    return con


def columns(con: duckdb.DuckDBPyConnection, relation: str) -> list[tuple[str, str]]:
    return [(name, kind) for name, kind, *_ in con.execute(f"DESCRIBE {relation}").fetchall()]


def iceberg_type(duckdb_type: str) -> str:
    if decimal := re.fullmatch(r"DECIMAL\((\d+),(\d+)\)", duckdb_type):
        return f"decimal({decimal[1]},{decimal[2]})"
    if duckdb_type not in ICEBERG_TYPES:
        raise SystemExit(f"No Iceberg type for DuckDB type {duckdb_type}")
    return ICEBERG_TYPES[duckdb_type]


def create_table(arn: str, ns: str, name: str, schema: list[tuple[str, str]]) -> None:
    """An Iceberg v3 table through the S3 Tables API, which, unlike DuckDB's CREATE TABLE, takes VARIANT columns."""
    fields = [{"id": i, "name": c, "type": iceberg_type(t), "required": False} for i, (c, t) in enumerate(schema, 1)]
    ids = {f["name"]: f["id"] for f in fields}
    iceberg = {"schemaV2": {"type": "struct", "fields": fields}, "properties": {"format-version": "3"}}
    time_column = TIME_COLUMNS.get(name)
    if time_column:
        iceberg["partitionSpec"] = {"fields": [{"sourceId": ids[time_column], "transform": "day",
                                                "name": f"{time_column}_day", "fieldId": 1000}]}
        iceberg["writeOrder"] = {"orderId": 1, "fields": [
            {"sourceId": ids[c], "transform": "identity", "direction": "asc", "nullOrder": "nulls-first"}
            for c in ZORDER]}
    client = boto3.client("s3tables", region_name=REGION)
    client.create_table(tableBucketARN=arn, namespace=ns, name=name, format="ICEBERG", metadata={"iceberg": iceberg})
    compaction = {"targetFileSizeMB": TARGET_FILE_MB} | ({"strategy": "z-order"} if time_column else {})
    client.put_table_maintenance_configuration(
        tableBucketARN=arn, namespace=ns, name=name, type="icebergCompaction",
        value={"status": "enabled", "settings": {"icebergCompaction": compaction}},
    )
    log(f"{ns}.{name}: created" + (f", by day of {time_column}, z-order {', '.join(ZORDER)}" if time_column else ""))


def ensure_table(con: duckdb.DuckDBPyConnection, arn: str, ns: str, name: str) -> None:
    """Creates the table if missing; fails if it exists with another schema, as made by an earlier generator."""
    schema = columns(con, f"_export_{name}")
    try:
        existing = columns(con, f"s3tables.{ns}.{name}")
    except duckdb.CatalogException:
        create_table(arn, ns, name, schema)
        return
    if existing != schema:
        raise SystemExit(f"{ns}.{name} exists with another schema; delete the namespace's tables to generate again")


def plan_chunks(day_sessions: list[int], per_chunk: int) -> list[dict]:
    chunks = []
    for day, sessions in enumerate(day_sessions):
        date = at.FIRST_DATE + datetime.timedelta(days=day)
        for first in range(0, sessions, per_chunk):
            last = min(first + per_chunk, sessions)
            chunks.append({"id": f"{date}/{first}", "day": day, "first": first, "last": last})
    return chunks


def plan(args: argparse.Namespace) -> None:
    if args.sessions_per_chunk < MIN_SESSIONS_PER_CHUNK:
        raise SystemExit(f"--sessions-per-chunk must be at least {MIN_SESSIONS_PER_CHUNK}, to hold a day's needles")
    arn = table_bucket_arn()
    ns = namespace(args.sf)
    con = connect(arn)
    con.execute(f"CREATE SCHEMA IF NOT EXISTS s3tables.{ns}")
    params = at.generator_params(args.sf, args.days)
    at.setup(con, params)
    db.execute(con, at.SQL_DIR / "dimensions.sql")
    at.generate_chunk(con, params, 0, 0, (0, 1))
    for name in at.DIMENSIONS + at.FACTS:
        ensure_table(con, arn, ns, name)
    for name in at.DIMENSIONS:
        if con.execute(f"SELECT count(*) FROM s3tables.{ns}.{name}").fetchone()[0] == 0:
            rows = con.execute(f"INSERT INTO s3tables.{ns}.{name} SELECT * FROM _export_{name}").fetchone()[0]
            log(f"{ns}.{name}: {rows:,} rows")
    sessions = at.day_sessions(con, params)
    chunks = plan_chunks(sessions, args.sessions_per_chunk)
    catalog = ia.Catalog(arn, REGION)
    locations = {name: catalog.load(ns, name)["location"].rstrip("/") for name in at.FACTS}
    args.out.write_text(json.dumps({
        "sf": args.sf, "namespace": ns, "table_bucket": arn, "days": args.days, "sessions": sum(sessions),
        "sessions_per_chunk": args.sessions_per_chunk, "tables": at.FACTS, "locations": locations,
        "chunks": chunks}))
    log(f"{ns}: {sum(sessions):,} sessions in {len(chunks):,} chunks")


class Coordinator:
    """The work API of the demo web app. post returns None when the coordinator answers 204 or 409."""

    def __init__(self, url: str, worker: str):
        self.url = url.rstrip("/")
        self.worker = worker

    def post(self, path: str, body: dict | None = None) -> dict | None:
        request = urllib.request.Request(
            self.url + path, data=json.dumps({"worker": self.worker} | (body or {})).encode(),
            headers={"Content-Type": "application/json"}, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.loads(response.read()) if response.status == 200 else None
        except urllib.error.HTTPError as e:
            if e.code == 409:
                return None
            raise


class Worker:
    """One process: a DuckDB connection, set up for the scale factor of the latest chunk."""

    def __init__(self, coordinator: Coordinator):
        self.coordinator = coordinator
        self.con: duckdb.DuckDBPyConnection | None = None
        self.setup_for: tuple | None = None

    def prepare(self, task: dict) -> dict:
        params = at.generator_params(task["sf"], task["days"])
        if self.setup_for != (task["sf"], task["days"]):
            self.con = db.connect(temp_dir=TEMP_DIR / "duckdb_tmp" / str(os.getpid()))
            self.con.execute("SET threads = 1")
            self.con.execute(f"SET memory_limit = '{PROCESS_MEMORY}'")
            self.con.execute("SET enable_progress_bar = false")
            db.execute(self.con, at.SQL_DIR / "s3_secret.sql", REGION=REGION)
            at.setup(self.con, params)
            self.setup_for = (task["sf"], task["days"])
        return params

    def run(self, task: dict) -> None:
        """Generates the chunk and writes its tables into their storage, for the coordinator to commit."""
        chunk = task["chunk"]
        started = time.monotonic()
        params = self.prepare(task)
        at.generate_chunk(self.con, params, chunk["day"], chunk["day"], (chunk["first"], chunk["last"]))
        generated = time.monotonic() - started
        started = time.monotonic()
        files = {table: self.write(task, table) for table in task["tables"]}
        taken = self.coordinator.post("/api/work/staged", {
            "sf": task["sf"], "chunk": chunk["id"], "lease": task["lease"], "files": files,
            "generate_seconds": round(generated, 1), "write_seconds": round(time.monotonic() - started, 1)})
        if taken is None:
            log(f"{chunk['id']}: the lease ended before it was staged, so another worker has it")

    def write(self, task: dict, table: str) -> list[dict]:
        """One parquet file per day partition, with the Iceberg field ids, which are the column positions.

        A file is part of the table only once the coordinator commits it; S3 Tables removes files never committed.
        """
        column = TIME_COLUMNS[table]
        names = [name for name, _ in columns(self.con, f"_export_{table}")]
        field_ids = ", ".join(f"{name}: {i}" for i, name in enumerate(names, 1))
        name = f"{task['chunk']['id'].replace('/', '-')}-{task['lease'][:8]}"
        files = []
        for (day,) in self.con.execute(f"SELECT DISTINCT {column}::DATE FROM _export_{table} ORDER BY 1").fetchall():
            path = f"{task['locations'][table]}/data/{column}_day={day}/{name}.parquet"
            rows = self.con.execute(f"COPY (SELECT * FROM _export_{table} WHERE {column}::DATE = '{day}') TO '{path}' "
                                    f"(FORMAT parquet, FIELD_IDS {{{field_ids}}})").fetchone()[0]
            size = self.con.execute(f"SELECT size FROM read_blob('{path}')").fetchone()[0]
            files.append({"path": path, "size": size, "rows": rows, "partition": [(day - EPOCH).days]})
        return files


def work_loop(url: str, parent: int) -> None:
    """Works until the parent process is gone, which daemon processes do not notice when it is killed."""
    # Containers on one host share its name and number their processes alike, so a random part tells them apart
    coordinator = Coordinator(url, f"{socket.gethostname()}:{os.getpid()}:{uuid.uuid4().hex[:6]}")
    worker = Worker(coordinator)
    while os.getppid() == parent:
        try:
            task = coordinator.post("/api/work")
        except (urllib.error.URLError, OSError) as e:
            log(f"coordinator unreachable: {e}")
            time.sleep(POLL_SECONDS)
            continue
        if task is None:
            time.sleep(POLL_SECONDS)
            continue
        try:
            worker.run(task)
        except Exception as e:
            log(f"{task['chunk']['id']}: {type(e).__name__}: {e}")
            coordinator.post("/api/work/failed", {"sf": task["sf"], "chunk": task["chunk"]["id"],
                                                  "lease": task["lease"], "error": f"{type(e).__name__}: {e}"})
            time.sleep(POLL_SECONDS)


def work(args: argparse.Namespace) -> None:
    """Runs --processes worker processes, one per CPU by default, replacing any that dies, until stopped."""
    processes = args.processes or os.cpu_count()
    log(f"{processes} processes of 1 thread and {PROCESS_MEMORY}, working for {args.coordinator}")
    context = multiprocessing.get_context("spawn")
    running: list[multiprocessing.Process] = []
    while True:
        running = [p for p in running if p.is_alive()]
        while len(running) < processes:
            process = context.Process(target=work_loop, args=(args.coordinator, os.getpid()), daemon=True)
            process.start()
            running.append(process)
        time.sleep(5)


def commit_files(catalog: ia.Catalog, ns: str, table: str, files: list[ia.StagedFile]) -> int:
    """Appends the files in one commit, again on top of any commit that got in first, such as a compaction."""
    for attempt in range(1, COMMIT_ATTEMPTS + 1):
        try:
            return ia.append(catalog, ns, table, files)
        except ia.CommitConflict:
            if attempt == COMMIT_ATTEMPTS:
                raise
            time.sleep(attempt * 0.5)


def commit(args: argparse.Namespace) -> None:
    """Commits for the coordinator: one JSON request per line on stdin, {id, namespace, table, files}, each
    answered on stdout with {id, snapshot}, the snapshot id as text, or {id, error}. Requests run in parallel, so tables commit at once."""
    catalog = ia.Catalog(table_bucket_arn(), REGION)
    lock = threading.Lock()

    def handle(line: str) -> None:
        request = json.loads(line)
        try:
            files = [ia.StagedFile(**f) for f in request["files"]]
            answer = {"snapshot": str(commit_files(catalog, request["namespace"], request["table"], files))}
        except Exception as e:
            answer = {"error": f"{type(e).__name__}: {e}"}
        with lock:
            print(json.dumps({"id": request["id"]} | answer), flush=True)

    with ThreadPoolExecutor(8) as pool:
        for line in sys.stdin:
            pool.submit(handle, line)


def maintenance(args: argparse.Namespace) -> None:
    client = boto3.client("s3tables", region_name=REGION)
    arn = table_bucket_arn()
    for name in at.DIMENSIONS + at.FACTS:
        status = client.get_table_maintenance_job_status(tableBucketARN=arn, namespace=namespace(args.sf), name=name)
        print(name, json.dumps(status["status"], default=str))


def expectation(name: str, sf: int):
    if name in SCALED:
        return SCALED[name] * sf * 0.98, SCALED[name] * sf * 1.02
    if name in BY_SF:
        return BY_SF[name].get(sf)
    return EXPECTED.get(name)


def validate(args: argparse.Namespace) -> None:
    """Prints each measure with the README's claim, and fails if any is outside it."""
    con = connect(table_bucket_arn())
    db.execute(con, at.SQL_DIR / "needles.sql")
    con.execute(f"SET search_path = 's3tables.{namespace(args.sf)},memory.main'")
    failed = []
    for name, actual in db.fetch_all(con, at.SQL_DIR / "validate.sql", NS=namespace(args.sf)):
        expected = expectation(name, args.sf)
        if expected is None:
            verdict = "measured"
        elif isinstance(expected, tuple):
            verdict = "ok" if expected[0] <= actual <= expected[1] else f"FAIL, expected {expected[0]:g} to {expected[1]:g}"
        else:
            verdict = "ok" if actual == expected else f"FAIL, expected {expected:g}"
        if verdict.startswith("FAIL"):
            failed.append(name)
        print(f"{name:50} {actual:>14,.2f}  {verdict}")
    if failed:
        raise SystemExit(f"{len(failed)} checks failed: {', '.join(failed)}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("step", choices=["plan", "work", "commit", "maintenance", "validate"])
    parser.add_argument("--sf", type=int, help="scale factor, for plan, maintenance and validate")
    parser.add_argument("--days", type=int, default=at.DAYS, help="days from 2025-01-01, fewer for tests")
    parser.add_argument("--sessions-per-chunk", type=int, default=SESSIONS_PER_CHUNK)
    parser.add_argument("--out", type=Path, help="plan: where to write the chunks, as JSON")
    parser.add_argument("--coordinator", help="work: URL of the demo web app")
    parser.add_argument("--processes", type=int, help="work: processes, default one per CPU")
    args = parser.parse_args()
    needed = {"plan": ["sf", "out"], "work": ["coordinator"], "commit": [], "maintenance": ["sf"],
              "validate": ["sf"]}[args.step]
    missing = [f"--{n}" for n in needed if getattr(args, n) is None]
    if missing:
        parser.error(f"{args.step} needs {', '.join(missing)}")
    {"plan": plan, "work": work, "commit": commit, "maintenance": maintenance, "validate": validate}[args.step](args)


if __name__ == "__main__":
    main()
