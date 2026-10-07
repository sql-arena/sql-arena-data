"""Access to the s3://sql-arena bucket.

Environment overrides:
  BUCKET=sql-arena
  AWS_PROFILE_NAME=sql-arena   (empty: use the default credential chain, e.g. on EC2)
"""

import json
import os
import shutil
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path

import boto3

from common import TEMP_DIR

BUCKET = os.environ.get("BUCKET", "sql-arena")
AWS_PROFILE_NAME = os.environ.get("AWS_PROFILE_NAME", "sql-arena")


def session() -> boto3.Session:
    return boto3.Session(profile_name=AWS_PROFILE_NAME or None)


class Bucket:
    """The bucket, or with upload=False a local mirror of it in temp/bucket for test runs."""

    def __init__(self, upload: bool = True):
        self.upload = upload
        self.name = BUCKET
        self.local = TEMP_DIR / "bucket"
        self.s3 = session().client("s3") if upload else None
        self.executor = ThreadPoolExecutor(max_workers=1)

    def keys(self, prefix: str) -> list[str]:
        if not self.upload:
            root = self.local / prefix
            files = root.rglob("*") if root.exists() else []
            return sorted(p.relative_to(self.local).as_posix() for p in files if p.is_file())
        pages = self.s3.get_paginator("list_objects_v2").paginate(Bucket=self.name, Prefix=prefix + "/")
        return sorted(o["Key"] for page in pages for o in page.get("Contents", []))

    def get_json(self, key: str) -> dict | None:
        if not self.upload:
            path = self.local / key
            return json.loads(path.read_text()) if path.exists() else None
        try:
            return json.loads(self.s3.get_object(Bucket=self.name, Key=key)["Body"].read())
        except self.s3.exceptions.NoSuchKey:
            return None

    def put_json(self, key: str, value: dict) -> None:
        body = json.dumps(value, indent=1)
        if not self.upload:
            path = self.local / key
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(body)
            return
        self.s3.put_object(Bucket=self.name, Key=key, Body=body.encode(), ContentType="application/json")

    def delete(self, keys: list[str]) -> None:
        if not self.upload:
            for key in keys:
                (self.local / key).unlink(missing_ok=True)
            return
        for i in range(0, len(keys), 1000):
            objects = [{"Key": k} for k in keys[i : i + 1000]]
            response = self.s3.delete_objects(Bucket=self.name, Delete={"Objects": objects, "Quiet": True})
            # Per-key failures such as AccessDenied are reported here instead of raised
            errors = response.get("Errors", [])
            if errors:
                failed = "\n".join(f"  {e['Key']}: {e['Code']} {e.get('Message', '')}" for e in errors)
                raise RuntimeError(f"Could not delete {len(errors)} objects from s3://{self.name}:\n{failed}")

    def put_files(self, files: list[tuple[Path, str]], keep: bool = False) -> Future:
        """Upload (path, key) pairs in the background, removing each local file once it is stored unless keep."""

        def run() -> None:
            for path, key in files:
                if self.upload:
                    self.s3.upload_file(str(path), self.name, key)
                    if not keep:
                        path.unlink()
                else:
                    target = self.local / key
                    target.parent.mkdir(parents=True, exist_ok=True)
                    (shutil.copyfile if keep else shutil.move)(path, target)

        return self.executor.submit(run)

    def close(self) -> None:
        self.executor.shutdown(wait=True)
