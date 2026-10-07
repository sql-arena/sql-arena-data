# TPC-DS

The [TPC-DS](https://www.tpc.org/tpcds/) decision support benchmark, generated with the DuckDB `tpcds` extension (`dsdgen`).

## Bucket Layout

```text
tpcds/sf<N>/<table>/<table>.{parquet,csv.zip}         # tables that fit in one file
tpcds/sf<N>/<table>/<table>_NNNN.{parquet,csv.zip}    # larger tables
tpcds/sf<N>/<table>/_manifest.json                    # parts written, for resuming
tpcds/sf<N>/queries/qNN.sql
```

Published scale factors: SF1.

Parquet files are about `--target-mb` (default 500 MB). The sales, returns and inventory tables are sorted by their date key (`ss_sold_date_sk`, `sr_returned_date_sk`, `cs_sold_date_sk`, `cr_returned_date_sk`, `ws_sold_date_sk`, `wr_returned_date_sk`, `inv_date_sk`). Dimensions keep generation order.

## Generating

```bash
uv run generate.py tpcds --sf 1
```

All 24 tables come from one `dsdgen` call. The DuckDB extension cannot generate TPC-DS in steps, so large scale factors must fit in memory plus DuckDB spill space under `temp/`.

## Restarting

Complete tables are skipped (`_manifest.json`). If any table is missing, the dataset is regenerated and only the missing tables are exported.

## Queries

`tpcds/sf<N>/queries/q01.sql` to `q99.sql`: the 99 TPC-DS queries from DuckDB's `tpcds_queries()` (DuckDB 1.5.6). Tables are qualified with the namespace, e.g. `tpcds_sf1.store_sales`. Extracted once and committed:

```bash
uv run generate.py tpcds --sf 1 --extract-queries
```

## Schema

The DDL is checked in at `tpcds/sf<N>/schema/` (one `<table>.sql` per table, plus `keys.sql` where keys apply) and uploaded unchanged with each run.
