# Generator Container

One image runs every generator in this repo. Build it from the repo root:

```bash
docker build -f docker/Dockerfile -t sql-arena-data .
```

Arguments are passed to `generate.py`:

```bash
docker run --rm -v /mnt/data:/opt/sql-arena-data/temp sql-arena-data tpch --sf 1000 --children 100
docker run --rm -v /mnt/data:/opt/sql-arena-data/temp sql-arena-data job --no-upload
```

Mount a large local disk on `/opt/sql-arena-data/temp`. It holds downloads, parts waiting for upload and DuckDB spill files.

## Credentials

The image sets `AWS_PROFILE_NAME=""`, so boto3 uses the default credential chain. On EC2 that is the instance role, which needs write access to `s3://sql-arena`. To run locally with the `sql-arena` SSO profile:

```bash
aws sso login --profile sql-arena
docker run --rm -v ~/.aws:/root/.aws -e AWS_PROFILE_NAME=sql-arena \
  -v "$PWD/temp:/opt/sql-arena-data/temp" sql-arena-data tpch --sf 1
```

Mount `~/.aws` writable: botocore saves the refreshed SSO token to `~/.aws/sso/cache`, and fails on a read-only mount once the token needs a refresh.

The bucket is in `eu-north-1`. Run the instance there to avoid cross-region transfer.
