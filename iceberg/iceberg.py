"""Iceberg metadata over the parquet files already in the bucket.

Usage:
  uv run generate.py iceberg [namespace ...] [--warehouse URI] [--no-upload]

See iceberg/README.md for the layout and how to rebuild metadata.
"""

import argparse
import sys
import tempfile
from pathlib import Path

import pyarrow.parquet as pq
from pyarrow import fs
from pyiceberg.catalog.sql import SqlCatalog

from common import TEMP_DIR, log
from common.bucket import BUCKET, Bucket, session

# Iceberg namespace -> object prefix holding one folder per table
DATASETS = {
    "job": "job",
    "nyctaxi": "nyctaxi",
    "publicbi": "publicbi",
    "telecomitalia": "telecomitalia",
    "tpch_sf1": "tpch/sf1",
    "tpch_sf1000": "tpch/sf1000",
    "tpcds_sf1": "tpcds/sf1",
}


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("datasets", nargs="*", default=list(DATASETS))
    parser.add_argument(
        "--warehouse", help=f"default s3://{BUCKET}/iceberg, or temp/iceberg with --no-upload"
    )


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    # The parquet files are always read from the real bucket; --no-upload only keeps the metadata local
    source = bucket if bucket.upload else Bucket()
    warehouse = args.warehouse or (f"s3://{BUCKET}/iceberg" if bucket.upload else (TEMP_DIR / "iceberg").as_uri())
    if warehouse.startswith("file://"):
        Path(warehouse.removeprefix("file://")).mkdir(parents=True, exist_ok=True)

    aws = session()
    creds = aws.get_credentials().get_frozen_credentials()
    region = source.s3.get_bucket_location(Bucket=BUCKET)["LocationConstraint"]
    arrow_s3 = fs.S3FileSystem(
        access_key=creds.access_key, secret_key=creds.secret_key, session_token=creds.token, region=region
    )
    writes_to_bucket = warehouse.startswith(f"s3://{BUCKET}/")
    warehouse_prefix = warehouse.removeprefix(f"s3://{BUCKET}/").rstrip("/")

    with tempfile.TemporaryDirectory() as tmp:
        catalog = SqlCatalog(
            "sql_arena",
            uri=f"sqlite:///{tmp}/catalog.db",
            warehouse=warehouse,
            **{
                "s3.access-key-id": creds.access_key,
                "s3.secret-access-key": creds.secret_key,
                "s3.session-token": creds.token,
                "s3.region": region,
            },
        )

        for dataset in args.datasets:
            source_prefix = DATASETS[dataset]
            files_by_table: dict[str, list[str]] = {}
            for key in source.keys(source_prefix):
                table_name = key.removeprefix(source_prefix + "/").split("/", 1)[0]
                if key.endswith(".parquet"):
                    files_by_table.setdefault(table_name, []).append(f"s3://{BUCKET}/{key}")
            if writes_to_bucket:
                stale = [t for t in files_by_table if source.keys(f"{warehouse_prefix}/{dataset}.db/{t}")]
                if stale:
                    sys.exit(
                        f"{dataset}: metadata already exists for {', '.join(stale)}; "
                        f"delete s3://{BUCKET}/{warehouse_prefix}/{dataset}.db/ first"
                    )

            catalog.create_namespace(dataset)
            for table_name, files in sorted(files_by_table.items()):
                schema = pq.read_schema(files[0].removeprefix("s3://"), filesystem=arrow_s3)
                table = catalog.create_table(
                    (dataset, table_name),
                    schema=schema,
                    location=f"{warehouse.rstrip('/')}/{dataset}.db/{table_name}",
                )
                table.add_files(file_paths=files)
                summary = table.current_snapshot().summary
                log(f"{dataset}.{table_name}: {len(files)} files, {summary['total-records']} rows -> {table.metadata_location}")

