# Iceberg Metadata

Iceberg tables over the parquet files the other generators put in the bucket. No data is copied: each table's data files are the existing parquet files, added with `add_files`.

## Bucket Layout

```text
iceberg/<namespace>.db/<table>/metadata/
```

The namespace is the dataset path with `/` replaced by `_`, for example `tpch/sf1000` becomes `tpch_sf1000`. The mapping is `DATASETS` in `iceberg.py`.

## Generating

Run this after a dataset is complete:

```bash
uv run generate.py iceberg tpch_sf1000
uv run generate.py iceberg tpch_sf1 --no-upload     # reads the bucket, writes metadata to temp/iceberg
```

## Rebuilding

The metadata is not incremental. A namespace that already has metadata is refused. Delete `s3://sql-arena/iceberg/<namespace>.db/` first, then rerun.
