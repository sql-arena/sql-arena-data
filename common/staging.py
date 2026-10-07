"""Local staging for tables generated in steps that must be exported in global order.

Each step's rows are written as parquet partitioned by a sort bucket (e.g. the month of the order column).
Once every step is staged, each bucket is sorted and exported in turn, so the parts cover consecutive ranges.
"""

import shutil
from pathlib import Path

import duckdb

from common import db, log
from common.export import TableExport


class Staging:
    def __init__(self, directory: Path, bucket: str, name: str):
        """bucket: SQL expression giving a bucket label that sorts in order; name: label used in paths and chunks."""
        self.directory = directory
        self.bucket = bucket
        self.name = name

    def staged(self, step: int) -> bool:
        return (self.directory / f"_staged_{step:04}").exists()

    def stage(self, con: duckdb.DuckDBPyConnection, source: str, step: int) -> None:
        self.directory.mkdir(parents=True, exist_ok=True)
        for partial in self.directory.glob(f"*/step_{step}_*.parquet"):
            partial.unlink()
        db.execute(
            con, db.SQL_DIR / "stage.sql",
            SOURCE=source, BUCKET=self.bucket, NAME=self.name, DIR=self.directory, STEP=step,
        )
        (self.directory / f"_staged_{step:04}").touch()

    def export(self, con: duckdb.DuckDBPyConnection, export: TableExport, order_by: str | None) -> None:
        """Export every bucket in order (each sorted by order_by if given), finish the table and remove the staging."""
        for bucket_dir in sorted(self.directory.glob(f"_{self.name}=*")):
            chunk = f"{self.name} {bucket_dir.name.split('=', 1)[1]}"
            if export.chunk_done(chunk):
                continue
            db.execute(con, db.SQL_DIR / "staged_bucket.sql", DIR=bucket_dir)
            export.write("_bucket", chunk, single_chunk=False, order_by=order_by)
            db.drop_table(con, "_bucket")
        export.finish()
        shutil.rmtree(self.directory)
        log(f"{export.folder}: exported from staging")
