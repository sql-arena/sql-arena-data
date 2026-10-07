# NYC Taxi

Trip records published by the [NYC Taxi & Limousine Commission](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), from 2009 to the latest published month, plus the taxi zone lookup.

## Source

Monthly parquet files at `https://d37ci6vzurychx.cloudfront.net/trip-data/<source>_tripdata_YYYY-MM.parquet` and the zone lookup at `https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv`.

CloudFront answers 403 both for a missing month and when it rate limits. A 403 only counts as "not published" while the zone lookup is still reachable. Otherwise the generator backs off and retries.

## Tables

| Table | Source | Months |
|---|---|---|
| `yellow_tripdata_legacy` | yellow | 2009-01 to 2010-12. These have coordinates instead of taxi zones and different codes |
| `yellow_tripdata` | yellow | 2011-01 onward |
| `green_tripdata` | green | 2014-01 onward |
| `fhv_tripdata` | fhv | 2015-01 onward |
| `fhvhv_tripdata` | fhvhv | 2019-02 onward |
| `taxi_zone` | zone lookup | |

The source schema drifts between years. Each table has one normalised schema: lower snake_case names and one type per column. Source columns are matched case-insensitively against the known names (`TABLES` in `nyctaxi.py`). A missing column becomes `NULL`, and unknown source columns are logged as a warning.

## Queries

There is no official query set for this data. `queries/q01.sql` to `q15.sql` are hand-written for SQL Arena. They cover:

- Single table aggregation, including the classic "billion taxi rides" queries (q02 to q04)
- Joins to `taxi_zone` (q05, q06, q08, q10, q12)
- Window functions (q08, q09, q14)
- A full outer join between services (q10)
- The legacy coordinate era (q13)
- Data quality counts (q15)

## Bucket Layout

```text
nyctaxi/<table>/<table>_NNNN.{parquet,csv.zip}
nyctaxi/<table>/_manifest.json
nyctaxi/taxi_zone/taxi_zone.{parquet,csv.zip}
nyctaxi/queries/<query>.sql
```

Months are written in order. Within a month, rows are sorted by `pickup_datetime`, so consecutive parts cover consecutive time ranges. Rows with a pickup time outside their file's month (dirty source data) stay with that month. Parts hold a fixed number of rows and may span month boundaries.

Parquet files are about `--target-mb` (default 500 MB). Row width changes over the years, so each table has eras (`eras` in `TABLES`). The rows per part of an era are measured on the first month of that era written. A part uses the rows per part of the era its first row belongs to.

## Generating

```bash
uv run generate.py nyctaxi                                   # all tables up to this month
uv run generate.py nyctaxi green_tripdata --until 2014-03 --no-upload
```

Downloads go to `temp/nyctaxi/` (override with `WORK_DIR`) and are removed once all their rows are in uploaded parts. The checked-in queries in `nyctaxi/queries/` are uploaded at the end of each run.

## Restarting and Appending

`_manifest.json` records the target size, the measured rows per part of each era, and which month rows went into which part. A rerun skips completed parts and rebuilds only the trailing partial part, so newly published months are appended.

- If a month's row count changes because the TLC republished it, the run stops. Delete `nyctaxi/<table>/` to rebuild.
- Changing `--target-mb` or a table's eras rebuilds every part of that table. Parts left over from the earlier layout are deleted at the end of the run.

## Schema

The DDL is checked in at `nyctaxi/schema/` (one `<table>.sql` per table, plus `keys.sql` where keys apply) and uploaded unchanged with each run.
