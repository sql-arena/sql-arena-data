"""NYC TLC trip records, normalised into one schema per table.

Usage:
  uv run generate.py nyctaxi [table ...] [--until YYYY-MM] [--no-upload]

See nyctaxi/README.md for the layout, the manifest and how resuming works.

Environment overrides:
  WORK_DIR=./temp/nyctaxi
"""

import argparse
import datetime
import os
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import Future
from dataclasses import dataclass
from pathlib import Path

import duckdb

from common import TEMP_DIR, db, log
from common.bucket import Bucket
from common.download import download
from common.export import SAMPLE_ROWS
from common.queries import publish_checked_in

WORK_DIR = Path(os.environ.get("WORK_DIR", TEMP_DIR / "nyctaxi"))
SQL_DIR = Path(__file__).parent / "sql"

DATASET = "nyctaxi"
SOURCE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"
ZONE_URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

# CloudFront answers 403 both for a missing month and when it rate limits us.
# Downloads are sequential, and a 403 is only treated as "missing" when this
# known file is still reachable.
SENTINEL_URL = ZONE_URL


@dataclass(frozen=True)
class Column:
    name: str
    type: str
    sources: tuple[str, ...]  # source column names across the years, matched case-insensitively


@dataclass(frozen=True)
class Table:
    name: str
    source: str  # prefix of the monthly files, e.g. yellow -> yellow_tripdata_2011-01.parquet
    first_month: str
    last_month: str | None  # None: until the latest published month
    # First month of each era: row width changes over the years, so the rows per part are measured
    # per era. A part uses the rows per part of the era its first row belongs to.
    eras: tuple[str, ...]
    columns: tuple[Column, ...]

    def era(self, month: str) -> str:
        return [first for first in self.eras if first <= month][-1]


def col(name: str, type_: str, *sources: str) -> Column:
    return Column(name, type_, sources or (name,))


TABLES = {
    t.name: t
    for t in [
        # 2009-2010 yellow trips have coordinates instead of taxi zones and different codes
        Table(
            "yellow_tripdata_legacy", "yellow", "2009-01", "2010-12", ("2009-01",),
            (
                col("vendor", "VARCHAR", "vendor_name", "vendor_id"),
                col("pickup_datetime", "TIMESTAMP", "Trip_Pickup_DateTime", "pickup_datetime"),
                col("dropoff_datetime", "TIMESTAMP", "Trip_Dropoff_DateTime", "dropoff_datetime"),
                col("passenger_count", "INTEGER"),
                col("trip_distance", "DOUBLE"),
                col("pickup_longitude", "DOUBLE", "Start_Lon", "pickup_longitude"),
                col("pickup_latitude", "DOUBLE", "Start_Lat", "pickup_latitude"),
                col("rate_code", "VARCHAR", "Rate_Code", "rate_code"),
                col("store_and_fwd_flag", "VARCHAR", "store_and_forward", "store_and_fwd_flag"),
                col("dropoff_longitude", "DOUBLE", "End_Lon", "dropoff_longitude"),
                col("dropoff_latitude", "DOUBLE", "End_Lat", "dropoff_latitude"),
                col("payment_type", "VARCHAR"),
                col("fare_amount", "DOUBLE", "Fare_Amt", "fare_amount"),
                col("surcharge", "DOUBLE"),
                col("mta_tax", "DOUBLE"),
                col("tip_amount", "DOUBLE", "Tip_Amt", "tip_amount"),
                col("tolls_amount", "DOUBLE", "Tolls_Amt", "tolls_amount"),
                col("total_amount", "DOUBLE", "Total_Amt", "total_amount"),
            ),
        ),
        Table(
            "yellow_tripdata", "yellow", "2011-01", None, ("2011-01", "2016-01"),
            (
                col("vendor_id", "INTEGER", "VendorID"),
                col("pickup_datetime", "TIMESTAMP", "tpep_pickup_datetime"),
                col("dropoff_datetime", "TIMESTAMP", "tpep_dropoff_datetime"),
                col("passenger_count", "INTEGER"),
                col("trip_distance", "DOUBLE"),
                col("rate_code_id", "INTEGER", "RatecodeID"),
                col("store_and_fwd_flag", "VARCHAR"),
                col("pu_location_id", "INTEGER", "PULocationID"),
                col("do_location_id", "INTEGER", "DOLocationID"),
                col("payment_type", "INTEGER"),
                col("fare_amount", "DOUBLE"),
                col("extra", "DOUBLE"),
                col("mta_tax", "DOUBLE"),
                col("tip_amount", "DOUBLE"),
                col("tolls_amount", "DOUBLE"),
                col("improvement_surcharge", "DOUBLE"),
                col("total_amount", "DOUBLE"),
                col("congestion_surcharge", "DOUBLE"),
                col("airport_fee", "DOUBLE"),
                col("cbd_congestion_fee", "DOUBLE"),
            ),
        ),
        Table(
            "green_tripdata", "green", "2014-01", None, ("2014-01",),
            (
                col("vendor_id", "INTEGER", "VendorID"),
                col("pickup_datetime", "TIMESTAMP", "lpep_pickup_datetime"),
                col("dropoff_datetime", "TIMESTAMP", "lpep_dropoff_datetime"),
                col("store_and_fwd_flag", "VARCHAR"),
                col("rate_code_id", "INTEGER", "RatecodeID"),
                col("pu_location_id", "INTEGER", "PULocationID"),
                col("do_location_id", "INTEGER", "DOLocationID"),
                col("passenger_count", "INTEGER"),
                col("trip_distance", "DOUBLE"),
                col("fare_amount", "DOUBLE"),
                col("extra", "DOUBLE"),
                col("mta_tax", "DOUBLE"),
                col("tip_amount", "DOUBLE"),
                col("tolls_amount", "DOUBLE"),
                col("ehail_fee", "DOUBLE"),
                col("improvement_surcharge", "DOUBLE"),
                col("total_amount", "DOUBLE"),
                col("payment_type", "INTEGER"),
                col("trip_type", "INTEGER"),
                col("congestion_surcharge", "DOUBLE"),
                col("cbd_congestion_fee", "DOUBLE"),
            ),
        ),
        Table(
            "fhv_tripdata", "fhv", "2015-01", None, ("2015-01", "2017-01", "2019-02"),
            (
                col("dispatching_base_num", "VARCHAR"),
                col("pickup_datetime", "TIMESTAMP"),
                col("dropoff_datetime", "TIMESTAMP"),
                col("pu_location_id", "INTEGER", "PUlocationID"),
                col("do_location_id", "INTEGER", "DOlocationID"),
                col("sr_flag", "INTEGER", "SR_Flag"),
                col("affiliated_base_number", "VARCHAR"),
            ),
        ),
        Table(
            "fhvhv_tripdata", "fhvhv", "2019-02", None, ("2019-02",),
            (
                col("hvfhs_license_num", "VARCHAR"),
                col("dispatching_base_num", "VARCHAR"),
                col("originating_base_num", "VARCHAR"),
                col("request_datetime", "TIMESTAMP"),
                col("on_scene_datetime", "TIMESTAMP"),
                col("pickup_datetime", "TIMESTAMP"),
                col("dropoff_datetime", "TIMESTAMP"),
                col("pu_location_id", "INTEGER", "PULocationID"),
                col("do_location_id", "INTEGER", "DOLocationID"),
                col("trip_miles", "DOUBLE"),
                col("trip_time", "BIGINT"),
                col("base_passenger_fare", "DOUBLE"),
                col("tolls", "DOUBLE"),
                col("bcf", "DOUBLE"),
                col("sales_tax", "DOUBLE"),
                col("congestion_surcharge", "DOUBLE"),
                col("airport_fee", "DOUBLE"),
                col("tips", "DOUBLE"),
                col("driver_pay", "DOUBLE"),
                col("shared_request_flag", "VARCHAR"),
                col("shared_match_flag", "VARCHAR"),
                col("access_a_ride_flag", "VARCHAR"),
                col("wav_request_flag", "VARCHAR"),
                col("wav_match_flag", "VARCHAR"),
                col("cbd_congestion_fee", "DOUBLE"),
            ),
        ),
    ]
}


def http_status(url: str) -> int:
    request = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.status
    except urllib.error.HTTPError as e:
        return e.code


def wait_until_not_rate_limited() -> None:
    delay = 30
    while http_status(SENTINEL_URL) != 200:
        log(f"Source is rate limiting us, sleeping {delay}s")
        time.sleep(delay)
        delay = min(delay * 2, 900)


def fetch(url: str, path: Path) -> bool:
    """Download url to path. Returns False when the file does not exist."""
    while True:
        try:
            download(url, path)
            return True
        except urllib.error.HTTPError as e:
            if e.code not in (403, 404, 429, 503):
                raise
            if http_status(SENTINEL_URL) == 200:
                return False
            wait_until_not_rate_limited()
        except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
            log(f"Download of {url} failed ({e}), retrying in 60s")
            time.sleep(60)


def months(first: str, last: str) -> list[str]:
    year, month = map(int, first.split("-"))
    result = []
    while f"{year:04}-{month:02}" <= last:
        result.append(f"{year:04}-{month:02}")
        year, month = (year + 1, 1) if month == 12 else (year, month + 1)
    return result


warned: set[Path] = set()


def month_select(con: duckdb.DuckDBPyConnection, table: Table, path: Path, segment: int, start: int, end: int) -> str:
    source_columns = {name.lower(): name for (name,) in db.fetch_all(con, SQL_DIR / "source_columns.sql", PATH=path)}
    used = set()
    expressions = []
    for c in table.columns:
        source = next((source_columns[s.lower()] for s in c.sources if s.lower() in source_columns), None)
        if source is None:
            expressions.append(f"CAST(NULL AS {c.type}) AS {c.name}")
        else:
            used.add(source)
            expressions.append(f'CAST("{source}" AS {c.type}) AS {c.name}')
    # __index_level_0__ is a pandas index some source files were written with
    unmapped = set(source_columns.values()) - used - {"__index_level_0__"}
    if unmapped and path not in warned:
        warned.add(path)
        log(f"WARNING {path.name}: source columns not in {table.name}: {sorted(unmapped)}")
    return db.read_sql(
        SQL_DIR / "month_select.sql", SEGMENT=segment, COLUMNS=", ".join(expressions), PATH=path, START=start, END=end
    )


def write_part(con: duckdb.DuckDBPyConnection, sql_file: str, out_dir: Path, stem: str, **params: object) -> list[Path]:
    db.execute(con, SQL_DIR / sql_file, **params)
    files = db.write_part(con, "part", out_dir, stem)
    db.drop_table(con, "part")
    return files


def measure_rows_per_part(con: duckdb.DuckDBPyConnection, table: Table, path: Path, target_bytes: int) -> int:
    """Rows of a month that fit in the target parquet size, measured on a sample of its normalised rows."""
    rows = min(db.fetch_value(con, SQL_DIR / "month_rows.sql", PATH=path), SAMPLE_ROWS)
    sample = path.with_name("_sample.parquet")
    db.write_parquet(con, f"({month_select(con, table, path, 0, 0, rows)})", sample)
    bytes_per_row = sample.stat().st_size / rows
    sample.unlink()
    return max(1, int(target_bytes / bytes_per_row))


def load_trips(con: duckdb.DuckDBPyConnection, bucket: Bucket, table: Table, until: str, target_bytes: int) -> None:
    prefix = f"{DATASET}/{table.name}"
    manifest_key = f"{prefix}/_manifest.json"
    manifest = bucket.get_json(manifest_key) or {}
    if (manifest.get("target_bytes"), manifest.get("eras")) != (target_bytes, list(table.eras)):
        if manifest.get("parts"):
            log(f"{table.name}: target size or eras changed, rebuilding all parts")
        manifest = {
            "target_bytes": target_bytes, "eras": list(table.eras), "rows_per_part": {},
            "months": manifest.get("months", {}), "parts": [],
        }
    work = WORK_DIR / table.name

    def part_rows(month: str) -> int:
        era = table.era(month)
        if era not in manifest["rows_per_part"]:
            manifest["rows_per_part"][era] = measure_rows_per_part(con, table, work / f"{month}.parquet", target_bytes)
            log(f"{table.name}: {manifest['rows_per_part'][era]} rows per part from {era}")
        return manifest["rows_per_part"][era]

    # The trailing part is rebuilt when it is not full, so later months can be appended to it
    parts = manifest["parts"]
    if parts:
        segments = parts[-1]["segments"]
        if sum(end - start for _, start, end in segments) < part_rows(segments[0][0]):
            parts.pop()
    month_rows: dict[str, int] = manifest["months"]

    # Position after the last completed part: (month, first row not yet in a part)
    position = (table.first_month, 0)
    if parts:
        month, _, end = parts[-1]["segments"][-1]
        position = (month, end)

    work.mkdir(parents=True, exist_ok=True)
    last_month = min(table.last_month or until, until)
    pending: list[tuple[str, int, int]] = []  # (month, start, end) rows not yet in a part
    pending_rows = 0
    upload: Future | None = None

    def flush(rows: int) -> None:
        nonlocal pending, pending_rows, upload
        segments, taken = [], 0
        while taken < rows:
            month, start, end = pending[0]
            n = min(end - start, rows - taken)
            segments.append((month, start, start + n))
            taken += n
            pending[0] = (month, start + n, end)
            if pending[0][1] == end:
                pending.pop(0)
        pending_rows -= rows

        number = len(parts)
        stem = f"{table.name}_{number:04}"
        selects = [
            month_select(con, table, work / f"{month}.parquet", i, start, end)
            for i, (month, start, end) in enumerate(segments)
        ]
        columns = ", ".join(c.name for c in table.columns)
        files = write_part(con, "part.sql", work, stem, COLUMNS=columns, SEGMENTS=" UNION ALL ".join(selects))
        if upload:
            upload.result()
        upload = bucket.put_files([(f, f"{prefix}/{f.name}") for f in files])
        parts.append({"part": number, "segments": [list(s) for s in segments]})
        log(f"{stem}: {rows} rows from {', '.join(m for m, _, _ in segments)}")

        # Months no longer referenced by pending rows can be removed locally
        keep = {m for m, _, _ in pending}
        for month, _, _ in segments:
            if month not in keep:
                (work / f"{month}.parquet").unlink(missing_ok=True)
        if number % 20 == 0:
            upload.result()
            bucket.put_json(manifest_key, manifest)

    for month in months(position[0], last_month):
        path = work / f"{month}.parquet"
        if not fetch(f"{SOURCE_URL}/{table.source}_tripdata_{month}.parquet", path):
            log(f"{table.name}: {month} is not published, stopping")
            break
        rows = db.fetch_value(con, SQL_DIR / "month_rows.sql", PATH=path)
        if month_rows.get(month, rows) != rows:
            sys.exit(f"{table.name}: {month} changed from {month_rows[month]} to {rows} rows; delete {prefix}/ to rebuild")
        month_rows[month] = rows
        start = position[1] if month == position[0] else 0
        if start < rows:
            pending.append((month, start, rows))
            pending_rows += rows - start
        while pending and pending_rows >= part_rows(pending[0][0]):
            flush(part_rows(pending[0][0]))

    if pending_rows:
        flush(pending_rows)
    if upload:
        upload.result()
    bucket.put_json(manifest_key, manifest)
    first_stale = f"{table.name}_{len(parts):04}"
    stale = [k for k in bucket.keys(prefix) if k.rsplit("/", 1)[-1] >= first_stale and not k.endswith(".json")]
    if stale:
        log(f"{table.name}: deleting {len(stale)} files of parts from an earlier layout")
        bucket.delete(stale)
    log(f"{table.name}: {len(parts)} parts, {sum(month_rows.values())} rows from {len(month_rows)} months")


def load_zones(con: duckdb.DuckDBPyConnection, bucket: Bucket) -> None:
    work = WORK_DIR / "taxi_zone"
    work.mkdir(parents=True, exist_ok=True)
    source = work / "taxi_zone_lookup.csv"
    if not fetch(ZONE_URL, source):
        sys.exit(f"{ZONE_URL} is not published")
    files = write_part(con, "zones.sql", work, "taxi_zone", PATH=source)
    bucket.put_files([(f, f"{DATASET}/taxi_zone/{f.name}") for f in files]).result()
    source.unlink()
    log("taxi_zone: uploaded")


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("tables", nargs="*", default=["taxi_zone", *TABLES])
    parser.add_argument("--until", default=f"{datetime.date.today():%Y-%m}", help="last month to load (YYYY-MM)")


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    con = db.connect(temp_dir=WORK_DIR / "duckdb_tmp")
    for name in args.tables:
        if name == "taxi_zone":
            load_zones(con, bucket)
        else:
            load_trips(con, bucket, TABLES[name], args.until, args.target_mb * 1_000_000)
    publish_checked_in(bucket, DATASET)

