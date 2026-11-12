"""Appends parquet files that are already in an Iceberg v3 table's storage to the table, in one commit, through the
S3 Tables REST catalog.

DuckDB can only add data to an Iceberg table by writing it again, and PyIceberg 0.12 can neither load a table with
VARIANT columns nor write v3 manifests. So this writes the manifest, the manifest list and the commit itself, with
PyIceberg's Avro writer and the v3 schemas of its manifest module. The data files must hold Iceberg field ids and
lie in one partition each.
"""

import dataclasses
import json
import random
import time
import urllib.parse
import uuid

import boto3
import requests
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from pyiceberg.avro.file import AvroFile, AvroOutputFile
from pyiceberg.io.pyarrow import PyArrowFileIO
from pyiceberg.manifest import (
    MANIFEST_LIST_FILE_SCHEMAS, PARTITION_FIELD_SUMMARY_TYPE, DataFile, DataFileContent, FileFormat, ManifestContent,
    ManifestEntry, ManifestEntryStatus, ManifestFile, PartitionFieldSummary, data_file_with_partition,
    manifest_entry_schema_with_data_file,
)
from pyiceberg.partitioning import PartitionSpec
from pyiceberg.schema import Schema
from pyiceberg.typedef import Record

VERSION = 3


class CommitConflict(Exception):
    """Another commit got in first; append again, which builds on it."""


@dataclasses.dataclass
class StagedFile:
    path: str
    size: int
    rows: int
    partition: list  # the value of each partition field, a day as days since 1970-01-01


class Catalog:
    """The S3 Tables Iceberg REST endpoint of one table bucket, with requests signed by the default credentials."""

    def __init__(self, arn: str, region: str):
        self.region = region
        self.base = f"https://s3tables.{region}.amazonaws.com/iceberg/v1/{urllib.parse.quote(arn, safe='')}"
        self.credentials = boto3.Session().get_credentials()

    def request(self, method: str, path: str, body: dict | None = None) -> requests.Response:
        data = json.dumps(body) if body is not None else None
        signed = AWSRequest(method=method, url=self.base + path, data=data,
                            headers={"Content-Type": "application/json"} if data else {})
        SigV4Auth(self.credentials.get_frozen_credentials(), "s3tables", self.region).add_auth(signed)
        return requests.request(method, signed.url, data=data, headers=dict(signed.headers), timeout=60)

    def load(self, ns: str, table: str) -> dict:
        response = self.request("GET", f"/namespaces/{ns}/tables/{table}")
        response.raise_for_status()
        return response.json()["metadata"]

    def commit(self, ns: str, table: str, body: dict) -> None:
        response = self.request("POST", f"/namespaces/{ns}/tables/{table}", body)
        if response.status_code == 409:
            raise CommitConflict(response.text)
        if response.status_code >= 400:
            raise RuntimeError(f"Commit to {ns}.{table} failed: {response.status_code} {response.text}")


def partition_spec(metadata: dict) -> tuple[PartitionSpec, Schema]:
    """The default partition spec, and a schema of just its source columns, which PyIceberg can parse."""
    spec_json = next(s for s in metadata["partition-specs"] if s["spec-id"] == metadata["default-spec-id"])
    table_schema = next(s for s in metadata["schemas"] if s["schema-id"] == metadata["current-schema-id"])
    sources = {f["source-id"] for f in spec_json["fields"]}
    schema = Schema.model_validate({"type": "struct", "schema-id": table_schema["schema-id"],
                                    "fields": [f for f in table_schema["fields"] if f["id"] in sources]})
    return PartitionSpec.model_validate(spec_json), schema


def write_manifest(io: PyArrowFileIO, path: str, metadata: dict, snapshot_id: int, files: list[StagedFile]) -> int:
    """Writes the manifest of the added files, and returns its length."""
    spec, schema = partition_spec(metadata)
    entry_schema = manifest_entry_schema_with_data_file(
        VERSION, data_file_with_partition(spec.partition_type(schema), VERSION))
    table_schema = next(s for s in metadata["schemas"] if s["schema-id"] == metadata["current-schema-id"])
    output = io.new_output(path)
    with AvroOutputFile[ManifestEntry](
            output_file=output, file_schema=entry_schema, record_schema=entry_schema, schema_name="manifest_entry",
            metadata={"schema": json.dumps(table_schema), "schema-id": str(table_schema["schema-id"]),
                      "partition-spec": json.dumps(spec_json_fields(metadata)),
                      "partition-spec-id": str(spec.spec_id), "format-version": str(VERSION), "content": "data"},
    ) as writer:
        writer.write_block([ManifestEntry.from_args(
            _table_format_version=VERSION, status=ManifestEntryStatus.ADDED, snapshot_id=snapshot_id,
            data_file=DataFile.from_args(
                _table_format_version=VERSION, content=DataFileContent.DATA, file_path=f.path,
                file_format=FileFormat.PARQUET, partition=Record(*f.partition), record_count=f.rows,
                file_size_in_bytes=f.size),
        ) for f in files])
    return len(io.new_input(path))


def spec_json_fields(metadata: dict) -> list:
    return next(s for s in metadata["partition-specs"] if s["spec-id"] == metadata["default-spec-id"])["fields"]


def partition_summaries(files: list[StagedFile], fields: int) -> list[PartitionFieldSummary]:
    """Bounds of each partition field over the files, as the manifest list keeps them for pruning manifests."""
    summaries = []
    for i in range(fields):
        values = [f.partition[i] for f in files]
        present = [v for v in values if v is not None]
        summaries.append(PartitionFieldSummary(
            len(present) < len(values), False,
            min(present).to_bytes(4, "little", signed=True) if present else None,
            max(present).to_bytes(4, "little", signed=True) if present else None))
    return summaries


def parent_manifests(io: PyArrowFileIO, metadata: dict) -> list[ManifestFile]:
    parent = next((s for s in metadata.get("snapshots", []) if s["snapshot-id"] == metadata.get("current-snapshot-id")),
                  None)
    if not parent:
        return []
    with AvroFile[ManifestFile](io.new_input(parent["manifest-list"]), MANIFEST_LIST_FILE_SCHEMAS[VERSION],
                                read_types={-1: ManifestFile, 508: PartitionFieldSummary},
                                read_enums={517: ManifestContent}) as reader:
        return list(reader)


def append(catalog: Catalog, ns: str, table: str, files: list[StagedFile]) -> int:
    """Commits files to the table as one append snapshot, and returns its id; raises CommitConflict if beaten."""
    metadata = catalog.load(ns, table)
    if metadata["format-version"] != VERSION:
        raise ValueError(f"{ns}.{table} is Iceberg v{metadata['format-version']}, not v{VERSION}")
    io = PyArrowFileIO({"s3.region": catalog.region})
    snapshot_id = random.getrandbits(62)
    parent_id = metadata.get("current-snapshot-id")
    parent_id = parent_id if parent_id is not None and parent_id >= 0 else None
    sequence = metadata["last-sequence-number"] + 1
    first_row_id = metadata.get("next-row-id", 0)
    location = metadata["location"].rstrip("/")
    added_rows = sum(f.rows for f in files)

    manifest_path = f"{location}/metadata/{uuid.uuid4()}-m0.avro"
    length = write_manifest(io, manifest_path, metadata, snapshot_id, files)
    spec_fields = spec_json_fields(metadata)
    manifest = ManifestFile.from_args(
        _table_format_version=VERSION, manifest_path=manifest_path, manifest_length=length,
        partition_spec_id=metadata["default-spec-id"], content=ManifestContent.DATA, sequence_number=sequence,
        min_sequence_number=sequence, added_snapshot_id=snapshot_id, added_files_count=len(files),
        existing_files_count=0, deleted_files_count=0, added_rows_count=added_rows, existing_rows_count=0,
        deleted_rows_count=0, partitions=partition_summaries(files, len(spec_fields)), first_row_id=first_row_id)

    list_path = f"{location}/metadata/snap-{snapshot_id}-1-{uuid.uuid4()}.avro"
    with AvroOutputFile[ManifestFile](
            output_file=io.new_output(list_path), file_schema=MANIFEST_LIST_FILE_SCHEMAS[VERSION],
            record_schema=MANIFEST_LIST_FILE_SCHEMAS[VERSION], schema_name="manifest_file",
            metadata={"snapshot-id": str(snapshot_id), "parent-snapshot-id": str(parent_id),
                      "sequence-number": str(sequence), "first-row-id": str(first_row_id),
                      "format-version": str(VERSION)},
    ) as writer:
        writer.write_block([manifest, *parent_manifests(io, metadata)])

    parent = next((s for s in metadata.get("snapshots", []) if s["snapshot-id"] == parent_id), None)
    totals = (parent or {}).get("summary", {})
    summary = {
        "operation": "append", "added-data-files": str(len(files)), "added-records": str(added_rows),
        "added-files-size": str(sum(f.size for f in files)),
        "total-data-files": str(int(totals.get("total-data-files", 0)) + len(files)),
        "total-records": str(int(totals.get("total-records", 0)) + added_rows),
        "total-files-size": str(int(totals.get("total-files-size", 0)) + sum(f.size for f in files)),
        "total-delete-files": totals.get("total-delete-files", "0"),
        "total-position-deletes": totals.get("total-position-deletes", "0"),
        "total-equality-deletes": totals.get("total-equality-deletes", "0"),
    }
    snapshot = {
        "snapshot-id": snapshot_id, "sequence-number": sequence, "timestamp-ms": int(time.time() * 1000),
        "manifest-list": list_path, "summary": summary, "schema-id": metadata["current-schema-id"],
        "first-row-id": first_row_id, "added-rows": added_rows,
    } | ({"parent-snapshot-id": parent_id} if parent_id is not None else {})
    catalog.commit(ns, table, {
        "requirements": [{"type": "assert-table-uuid", "uuid": metadata["table-uuid"]},
                         {"type": "assert-ref-snapshot-id", "ref": "main", "snapshot-id": parent_id}],
        "updates": [{"action": "add-snapshot", "snapshot": snapshot},
                    {"action": "set-snapshot-ref", "ref-name": "main", "type": "branch", "snapshot-id": snapshot_id}],
    })
    return snapshot_id
