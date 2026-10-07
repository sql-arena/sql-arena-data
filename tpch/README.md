# TPC-H

The [TPC-H](https://www.tpc.org/tpch/) decision support benchmark, generated with the DuckDB `tpch` extension (`dbgen`).

## Bucket Layout

```text
tpch/sf<N>/<table>/<table>.{parquet,csv.zip}          # tables that fit in one file
tpch/sf<N>/<table>/<table>_NNNN.{parquet,csv.zip}     # larger tables
tpch/sf<N>/<table>/_manifest.json                     # parts written, for resuming
tpch/sf<N>/queries/qNN.sql
```

Published scale factors: SF1 and SF1000.

Parquet files are about `--target-mb` (default 500 MB). Rows are sorted by date: `lineitem` by `l_shipdate`, `orders` by `o_orderdate`, so the parts of those tables cover consecutive date ranges. The other tables keep generation order.

## Generating

```bash
uv run generate.py tpch --sf 1
uv run generate.py tpch --sf 1000 --children 100
uv run generate.py tpch --sf 1000 --children 100 --steps 40-59
```

`--children N` generates `lineitem`, `orders` and `partsupp` one `dbgen` step at a time, to bound memory. `partsupp` parts are exported per step. Steps of `lineitem` and `orders` are staged locally as parquet in `temp/tpch/sf<N>/staging/`, partitioned by month. Once every step is staged, each month is sorted and exported, so all steps must run on the same machine. At SF1000 the staging needs about 300 GB of disk. `customer`, `nation`, `part`, `region` and `supplier` always come from one full `dbgen` call.

## Restarting

Rerun the same command. `_manifest.json` records the parts uploaded per step or month. Completed tables are skipped, and a table resumes at its first missing part. Staged steps are kept in `temp/` until their table is complete. When a table completes, files in its folder that are not in its manifest, e.g. from an earlier part size, are deleted.

## Queries

`tpch/sf<N>/queries/q01.sql` to `q22.sql`: the 22 TPC-H queries from DuckDB's `tpch_queries()` (DuckDB 1.5.6), with the validation parameters. Q11's `FRACTION` is set to `0.0001 / SF` as the specification requires. Tables are qualified with the namespace, e.g. `tpch_sf1000.lineitem`.

They are extracted once into the repo and committed. Generation uploads them unchanged:

```bash
uv run generate.py tpch --sf 1000 --extract-queries
```

## Schema

The DDL is checked in at `tpch/sf<N>/schema/` (one `<table>.sql` per table, plus `keys.sql` where keys apply) and uploaded unchanged with each run.
