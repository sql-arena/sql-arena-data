# SQL Arena Data Gen

Tools to generate the datasets used by SQL Arena and publish them to the public bucket.

## Public Bucket

All datasets are published to:

```text
s3://sql-arena            (eu-north-1, public read)
s3://sql-arena-us-east    (us-east-1, replica of s3://sql-arena)
```

Only the `sql-arena` AWS account can write to the bucket. 

Writers authenticate with the
`sql-arena` SSO profile that needs to be accessible on the machine running the generator

```bash
aws sso login --profile sql-arena
```

The bucket is versioned and replicates every write and delete to `s3://sql-arena-us-east`.
A description of the bucket for consumers lives at `s3://sql-arena/README.md`.

## Layout in the S3 Bucket

Every table lives in its own folder:

```text
<dataset>/<table>/<table>.{parquet,csv.zip}              # single file tables
<dataset>/<table>/<table>_NNNN.{parquet,csv.zip}         # large tables split into parts
iceberg/<namespace>.db/<table>/metadata/                 # Iceberg metadata over the parquet files
```

**Example:** `job/actor/actor.parquet`

A scale factor can optionally be appended to the `<dataset>` creating the struture
`<dataset>/<scale factor>/<table>/<table>.{parquet,csv.zip}`

**Example:** `tpch/sf1/orders/orders.parquet`

The Iceberg namespace is the dataset path with `/` replaced by `_` 

**Example:** (`tpch/sf1000` -> `tpch_sf1000`).

## DDL / Schemas

The schema of the dataset is stored under `<dataset>/<scale factor>/schema`

One file per table with name `<table>.sql`

Foreign keys, if applicable, are stored in: `<dataset>/<scale factor>/schema/keys.sql`.

The DDL shall contain only simple data types and NULL/NOT NULL information.

The allowed data types are those supported by Iceberg.

## Queries

SQL queries against the dataset, with all parameters replaced by actual values, are checked into
this repo and published unchanged to the same path in the bucket:

`<dataset path>/queries/<query_name>.sql`

The dataset path includes the scale factor when queries depend on it.

**Example:** `tpch/sf1/queries/q11.sql`

- One query per file, starting with a comment naming the query, e.g. `/* TPC-H Q18 */`
- Tables are qualified with the namespace of the dataset path, e.g. `FROM tpch_sf1.lineitem`

## Data Format

Every table is available in two formats:

- Zipped CSV (`.csv.zip`)
  - `|` column separator
  - `\n` row separator (LF / 0x0A)
  - Quoted strings (where needed)
  - First line is the header
- Parquet with min/max and all other metadata at maximum granularity
  - This typically requires a Spark data writer or similar
  - If there is a natural date/timestamp column, files are stored sorted by that

## Data Generation

Python with [uv](https://docs.astral.sh/uv/) orchestrates the generation, and DuckDB does the transformation. Set up the environment once:

```bash
uv sync
```

Every dataset is generated through the single entrypoint `generate.py`:

```bash
uv run generate.py <dataset> [options]          # e.g. uv run generate.py tpch --sf 1000 --children 100
uv run generate.py <dataset> --no-upload        # test run: writes to temp/bucket instead of the bucket
```

Large datasets are generated on a temporary EC2 instance in the same region as the bucket, using the container in [docker/](./docker/README.md).

See [CONVENTIONS.md](./CONVENTIONS.md) for details on invocation and naming of generation scripts.

See [DATASETS.md](./DATASETS.md) for details of the datasets that can currently be generated.

### Candidate Datasets

Research into further datasets and generators to add is in [CANDIDATE_DATASETS.md](./CANDIDATE_DATASETS.md).

## Data Chopping / Number of Files

Tables are split into parquet files of roughly 500 MB per file - after compression.
This is the default size, data generators must be parameterised with the target file size to control this number if needed.

## Iceberg Metadata

Once a dataset is complete, Iceberg metadata is generated with `uv run generate.py iceberg <namespace>`. See [iceberg/README.md](./iceberg/README.md).