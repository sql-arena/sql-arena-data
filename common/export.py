"""Export of DuckDB tables as parts of a target parquet size: <prefix>/<table>/<stem>.{parquet,csv.zip}

<prefix>/<table>/_manifest.json records the parts planned and uploaded for each chunk of a table (a chunk is the
whole table, or one generation step of it). A rerun resumes at the first part not uploaded, and once a table is
complete, files in its folder that are not in the manifest, e.g. from an earlier layout, are deleted.

A table can be generated in shards that run at the same time, on several machines: shard k of n records its chunks in
<prefix>/<table>/_manifest_<k>_of_<n>.json, and once every shard is complete, merge_shards() combines them.
"""

import math
from pathlib import Path

import duckdb

from common import TEMP_DIR, db, log
from common.bucket import Bucket

FORMATS = ("parquet", "csv.zip")
SAMPLE_ROWS = 1_000_000


class Exporter:
    def __init__(
        self, con: duckdb.DuckDBPyConnection, bucket: Bucket, prefix: str, target_mb: int, settings: dict | None = None,
        csv: bool = True, shard: tuple[int, int] | None = None,
    ):
        """settings: generator options that decide a table's chunks; a table is rebuilt when they change.

        csv: also write each part as csv.zip. shard: (k, n), this is shard k of n.
        """
        self.con = con
        self.bucket = bucket
        self.prefix = prefix
        self.target_bytes = target_mb * 1_000_000
        self.settings = settings or {}
        self.formats = FORMATS if csv else ("parquet",)
        self.shard = shard
        self.work = TEMP_DIR / prefix / (f"shard_{shard[0]}_of_{shard[1]}" if shard else "")

    def table(self, name: str) -> "TableExport":
        return TableExport(self, name)

    def export(self, name: str, source: str, order_by: str | None = None) -> None:
        """Export a whole table, unless it is complete in the bucket."""
        table = self.table(name)
        if not table.complete:
            table.write(source, order_by=order_by)
            table.finish()

    def rows_per_part(self, source: str, rows: int) -> int:
        """Measure the parquet size of a sample to find how many rows fit in the target size."""
        sample_rows = min(rows, SAMPLE_ROWS)
        path = self.work / "_sample.parquet"
        self.work.mkdir(parents=True, exist_ok=True)
        db.write_parquet(self.con, db.row_range(source, 0, sample_rows), path)
        bytes_per_row = path.stat().st_size / max(sample_rows, 1)
        path.unlink()
        return max(1, int(self.target_bytes / bytes_per_row))


class TableExport:
    def __init__(self, exporter: Exporter, name: str):
        self.exporter = exporter
        self.name = name
        self.folder = f"{exporter.prefix}/{name}"
        self.manifest_key = f"{self.folder}/_manifest.json"
        if exporter.shard:
            self.manifest_key = f"{self.folder}/_manifest_{exporter.shard[0]}_of_{exporter.shard[1]}.json"
        manifest = exporter.bucket.get_json(self.manifest_key)
        # Manifests from before settings were recorded take the current settings
        if manifest is not None:
            manifest.setdefault("settings", exporter.settings)
        if manifest is None or (manifest["target_bytes"], manifest["settings"]) != (exporter.target_bytes, exporter.settings):
            if manifest is not None:
                log(f"{self.folder}: target size or settings changed, rebuilding")
            manifest = {"target_bytes": exporter.target_bytes, "settings": exporter.settings, "complete": False, "chunks": {}}
        self.manifest = manifest

    @property
    def complete(self) -> bool:
        return self.manifest["complete"]

    def chunk_done(self, chunk: str) -> bool:
        c = self.manifest["chunks"].get(chunk)
        return c is not None and len(c["done"]) == len(c["stems"])

    def write(
        self, source: str, chunk: str = "all", single_chunk: bool = True, order_by: str | None = None,
        stem: str | None = None,
    ) -> None:
        """Export one chunk of the table, sorted by order_by if given.

        A single chunk table that fits in one part is named <table>. Parts are numbered across the table's chunks,
        or within the chunk as <stem>_NN when stem is given, as shards must.
        """
        if self.chunk_done(chunk):
            return
        e = self.exporter
        if order_by:
            db.execute(e.con, db.SQL_DIR / "sorted.sql", SOURCE=source, ORDER_BY=order_by)
            source = "_sorted"
        chunks = self.manifest["chunks"]
        if chunk not in chunks:
            rows = db.row_count(e.con, source)
            rows_per_part = e.rows_per_part(source, rows)
            parts = max(1, math.ceil(rows / rows_per_part))
            first = sum(len(c["stems"]) for c in chunks.values())
            if stem:
                stems = [f"{stem}_{i:02}" for i in range(parts)]
            elif single_chunk and parts == 1:
                stems = [self.name]
            else:
                stems = [f"{self.name}_{first + i:04}" for i in range(parts)]
            chunks[chunk] = {"rows_per_part": rows_per_part, "stems": stems, "done": []}
        c = chunks[chunk]
        for i, part_stem in enumerate(c["stems"]):
            if part_stem in c["done"]:
                continue
            part = db.row_range(source, i * c["rows_per_part"], (i + 1) * c["rows_per_part"])
            files = db.write_part(e.con, part, e.work, part_stem, csv="csv.zip" in e.formats)
            e.bucket.put_files([(f, f"{self.folder}/{f.name}") for f in files]).result()
            c["done"].append(part_stem)
            e.bucket.put_json(self.manifest_key, self.manifest)
            log(f"{self.folder}/{part_stem}: uploaded")
        if order_by:
            db.drop_table(e.con, "_sorted")

    def finish(self) -> None:
        """Mark the table complete and delete files in its folder that are not part of it.

        A shard is only marked complete: the files of the other shards are in the folder too.
        """
        if self.exporter.shard:
            self.manifest["complete"] = True
            self.exporter.bucket.put_json(self.manifest_key, self.manifest)
            return
        stems = {stem for c in self.manifest["chunks"].values() for stem in c["stems"]}
        keep = {f"{self.folder}/{stem}.{f}" for stem in stems for f in self.exporter.formats} | {self.manifest_key}
        stale = [k for k in self.exporter.bucket.keys(self.folder) if k not in keep]
        if stale:
            log(f"{self.folder}: deleting {len(stale)} files from an earlier layout")
            self.exporter.bucket.delete(stale)
        self.manifest["complete"] = True
        self.exporter.bucket.put_json(self.manifest_key, self.manifest)


    def merge_shards(self, shards: int) -> bool:
        """Combine the manifests of shards 0..shards-1 into this table's manifest and finish it, deleting the shard
        manifests. False, changing nothing, while a shard is missing or incomplete."""
        if self.complete:
            return True
        # A merge that was interrupted after writing the combined manifest only has to finish
        if not self.manifest["chunks"]:
            keys = [f"{self.folder}/_manifest_{k}_of_{shards}.json" for k in range(shards)]
            manifests = [self.exporter.bucket.get_json(key) for key in keys]
            if any(m is None or not m["complete"] for m in manifests):
                return False
            for m in manifests:
                if (m["target_bytes"], m["settings"]) != (self.manifest["target_bytes"], self.manifest["settings"]):
                    raise SystemExit(f"{self.folder}: shards were generated with other settings than {self.manifest['settings']}")
                self.manifest["chunks"].update(m["chunks"])
            self.exporter.bucket.put_json(self.manifest_key, self.manifest)
        self.finish()
        log(f"{self.folder}: merged {shards} shards, {len(self.manifest['chunks'])} chunks")
        return True
