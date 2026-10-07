# Join Order Benchmark (JOB)

The IMDB snapshot used by the Join Order Benchmark, from Leis et al., ["How Good Are Query Optimizers, Really?"](https://www.vldb.org/pvldb/vol9/p204-leis.pdf) (VLDB 2015).

## Source

`https://event.cwi.nl/da/job/imdb.tgz` (1.2 GB). The archive holds one comma-separated file per table and `schematext.sql` with the table definitions.

## Bucket Layout

```text
job/<table>/<table>.{parquet,csv.zip}           # tables that fit in one file
job/<table>/<table>_NNNN.{parquet,csv.zip}      # larger tables
job/<table>/_manifest.json                      # parts written, for resuming
job/queries/<query>.sql
```

There are 21 tables. Column types come from `schematext.sql`. Parquet files are about `--target-mb` (default 500 MB). `title` and `aka_title` are sorted by `production_year`, the year column the queries filter on. IMDB has no other date columns, so the other tables keep source order.

## Generating

```bash
uv run generate.py job
```

The archive is downloaded to `temp/job/source/`. Each table is extracted, loaded into DuckDB with `job/sql/load.sql`, exported, and then removed from DuckDB and disk.

## Restarting

Complete tables are skipped (`_manifest.json`), and the archive is not downloaded again while it is in `temp/job/source/`.

## Queries

`job/queries/1a.sql` to `33c.sql`: the 113 JOB queries from [gregrahn/join-order-benchmark](https://github.com/gregrahn/join-order-benchmark) at commit `a39603662e023e449cb2121997a5034df9e02ebf`. Tables are qualified with the namespace, e.g. `job.title`.

Queries 15a-15d alias `aka_title` as `at`, which DuckDB parses as a keyword. The extraction quotes it as `"at"`, which is valid in every dialect, and leaves the queries otherwise unchanged. Extracted once and committed:

```bash
uv run generate.py job --extract-queries
```

## Schema

The DDL is checked in at `job/schema/` (one `<table>.sql` per table, plus `keys.sql` where keys apply) and uploaded unchanged with each run.
