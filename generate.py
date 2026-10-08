"""Generate the SQL Arena datasets and publish them to the bucket.

Usage:
  uv run generate.py <dataset> [options] [--no-upload]
  uv run generate.py <dataset> --help

--no-upload writes into temp/bucket instead of the bucket, for testing.
"""

import argparse
import sys

from common.bucket import Bucket
from flowkit import flowkit
from iceberg import iceberg
from job import job
from nyctaxi import nyctaxi
from publicbi import publicbi
from telecomitalia import telecomitalia
from tpcds import tpcds
from tpch import tpch

GENERATORS = {"flowkit": flowkit, "job": job, "nyctaxi": nyctaxi, "publicbi": publicbi, "tpch": tpch, "tpcds": tpcds, "telecomitalia": telecomitalia, "iceberg": iceberg}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    subparsers = parser.add_subparsers(dest="dataset", required=True)
    for name, module in GENERATORS.items():
        subparser = subparsers.add_parser(name, help=module.__doc__.strip().splitlines()[0])
        subparser.add_argument("--no-upload", action="store_true", help="write to temp/bucket instead of the bucket")
        subparser.add_argument(
            "--target-mb", type=int, default=500, help="target size of each parquet file in MB, default 500"
        )
        if name != "iceberg":
            subparser.add_argument(
                "--checked-in-only", action="store_true",
                help="only upload the checked-in queries/ and schema/, without generating data",
            )
        module.add_arguments(subparser)
    args = parser.parse_args()

    bucket = Bucket(upload=not args.no_upload)
    try:
        GENERATORS[args.dataset].generate(bucket, args)
    finally:
        bucket.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
