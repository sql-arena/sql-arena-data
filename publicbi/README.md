# Public BI Benchmark

Real data and queries from 46 of the largest workbooks on [Tableau Public](https://public.tableau.com). From Vogelsgesang et al., "Get Real: How Benchmarks Fail to Represent the Real World" (DBTest 2018), as prepared by CWI in [cwida/public_bi_benchmark](https://github.com/cwida/public_bi_benchmark).

- 46 workbooks, 206 tables, 43 GB compressed (bzip2), 386 GB uncompressed
- 646 queries: the SQL Tableau issued while rendering the workbooks, adapted to run on MonetDB. They are in the repository under `benchmark/<workbook>/queries/`.
- Tables in a workbook may overlap, because Tableau extracted the same data in different ways for different visualisations.
- The repository code is MIT licensed. The data is public Tableau Public workbook data.

## Source

The schema (`benchmark/<workbook>/tables/<table>.table.sql`) and data URLs (`data-urls.txt`) come from the repository at commit `cf9909083bf9ed185cd7f5121a2881e1fea0e7a9`, pinned in `publicbi.py`. The data is one `<table>.csv.bz2` per table at `https://event.cwi.nl/da/PublicBIbenchmark/<workbook>/`.

The source files are `|` separated with no header and no quoting. `null` is NULL, and a backslash escapes the next character, so `\|` is a literal `|` inside a value. That is the format MonetDB's `COPY INTO` reads. DuckDB's CSV reader cannot unescape outside quotes, so `sql/load.sql` reads each line as one string and splits it in SQL. A row with the wrong number of fields stops the load.

## Bucket Layout

```text
publicbi/<table>/<table>.{parquet,csv.zip}            # tables that fit in one file
publicbi/<table>/<table>_NNNN.{parquet,csv.zip}       # larger tables
publicbi/<table>/_manifest.json                       # parts written, for resuming
publicbi/queries/<Workbook>_<N>.sql
```

Table and column names keep their original case and spaces, for example `publicbi/Arade_1/` with column `"Number of Records"`, so the benchmark queries run unchanged.

Parquet files are about `--target-mb` (default 500 MB). Each table is sorted by the date or timestamp column its workbook's queries reference most (`sql/order_column.sql`). Without such references it uses the table's first date or timestamp column. Tables with neither keep source order.

## Generating

```bash
uv run generate.py publicbi                       # all workbooks
uv run generate.py publicbi Arade Euro2016 --no-upload
```

The next table is downloaded and decompressed while the current one is loaded and exported. bzip2 decompression is the bottleneck, at about 4.5 MB/s of compressed input, so the full benchmark takes around 3 hours. Disk use peaks at about two uncompressed tables plus DuckDB spill. The largest table, `RealEstate1_2`, is 1.1 GB compressed.

## Restarting

Complete tables are skipped (`_manifest.json`), so a rerun only downloads the tables not yet in the bucket. A partly exported table is downloaded again and resumes at its first missing part.

## Queries

`publicbi/queries/<Workbook>_<N>.sql`: the 646 queries from `benchmark/<workbook>/queries/<N>.sql` in the repository at the pinned commit. Tables are qualified with the namespace, e.g. `publicbi."Arade_1"`. Column references like `"Arade_1"."F3"` are unchanged. The queries are in MonetDB's dialect, and 15 of them use functions DuckDB lacks (e.g. `locate`, `splitpart`). Extracted once and committed:

```bash
uv run generate.py publicbi --extract-queries
```

## Schema

The DDL is checked in at `publicbi/schema/` (one `<table>.sql` per table, plus `keys.sql` where keys apply) and uploaded unchanged with each run.
