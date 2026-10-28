"""Splunk Boss of the SOC v1: logs of a real attack on a company network, one table per Splunk sourcetype."""

import argparse
import csv
import re
from dataclasses import dataclass
from pathlib import Path

import duckdb

from common import REPO_ROOT, TEMP_DIR, db, log
from common.bucket import Bucket
from common.download import download, retry
from common.export import Exporter
from common.queries import publish_checked_in

DATASET = "bots"
SOURCE_URL = "https://s3.amazonaws.com/botsdataset/botsv1/json-by-sourcetype/botsv1.{file}.json.gz"
SQL_DIR = Path(__file__).parent / "sql"
FIELDS = Path(__file__).parent / "fields.csv"
WORK_DIR = TEMP_DIR / DATASET

# Table name: source file of the sourcetype
TABLES = {
    "wineventlog_application": "WinEventLog-Application",
    "wineventlog_security": "WinEventLog-Security",
    "wineventlog_system": "WinEventLog-System",
    "sysmon": "XmlWinEventLog-Microsoft-Windows-Sysmon-Operational",
    "winregistry": "winregistry",
    "fgt_event": "fgt_event",
    "fgt_traffic": "fgt_traffic",
    "fgt_utm": "fgt_utm",
    "iis": "iis",
    "nessus_scan": "nessus-scan",
    "stream_dhcp": "stream-dhcp",
    "stream_dns": "stream-dns",
    "stream_http": "stream-http",
    "stream_icmp": "stream-icmp",
    "stream_ip": "stream-ip",
    "stream_ldap": "stream-ldap",
    "stream_mapi": "stream-mapi",
    "stream_sip": "stream-sip",
    "stream_smb": "stream-smb",
    "stream_snmp": "stream-snmp",
    "stream_tcp": "stream-tcp",
    "suricata": "suricata",
}

# Fields Splunk adds when it indexes or searches, not from the logs. _time is computed from _time and _subsecond.
SPLUNK_FIELDS = {
    "_bkt", "_cd", "_eventtype_color", "_indextime", "_kv", "_pre_msg", "_serial", "_si", "_sourcetype",
    "_subsecond", "_time", "eventtype", "index", "linecount", "punct", "sourcetype", "splunk_server", "tag",
    "timeendpos", "timestartpos",
}
SPLUNK_PATTERN = re.compile(r"date_.*|tag::.*")
# Published scale factors, each with its schema in the repo
SCALE_FACTORS = (1, 10)
# Copies of the haystack: copy 1 is the original, so at most 255 fit in 10.<copy>.0.0/16
MAX_SF = 255
# Internal host names (we8105desk, we1149srv) and addresses (192.168.250.100), renamed in each copy
HOST = r"(?i)\b(we[0-9]{4}(?:srv|desk))\b"
ADDRESS = r"\b192\.168\.([0-9]{1,3}\.[0-9]{1,3})\b"


@dataclass(frozen=True)
class Field:
    table: str
    column: str
    type: str
    keys: list[str]


def add_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("tables", nargs="*", default=list(TABLES), help="tables to generate, default all")
    parser.add_argument(
        "--sf", type=int, default=1,
        help=f"scale factor: the original plus sf - 1 renamed copies of its non-attack events, at most {MAX_SF}",
    )
    parser.add_argument(
        "--extract-fields", action="store_true",
        help="profile the given tables and write fields.csv and the schema of every scale factor to the repo, "
             "for review and commit, instead of generating data",
    )


def fetch(table: str) -> Path:
    path = WORK_DIR / "source" / f"{TABLES[table]}.json.gz"
    if not path.exists():
        log(f"{DATASET}/{table}: downloading")
        retry(lambda: download(SOURCE_URL.format(file=TABLES[table]), path))
    return path


def column_name(key: str, reserved: set[str]) -> str:
    """Lower case snake_case, without the {} Splunk marks multi-valued fields with: cs_version{} is cs_version.

    Names are cut to Postgres' 63 characters, and a reserved word gets a trailing _ so it needs no quotes.
    """
    name = re.sub(r"[^a-z0-9]+", "_", key.replace("{}", "").lower()).strip("_")[:63].rstrip("_")
    return f"{name}_" if name in reserved else name


def column_type(stats: list[tuple]) -> str:
    """BIGINT or DOUBLE when every value of the keys is one, else VARCHAR. Arrays are joined to text."""
    n, arrays, integers, decimals = (sum(s[i] for s in stats) for i in range(1, 5))
    if arrays:
        return "VARCHAR"
    if integers == n:
        return "BIGINT"
    if integers + decimals == n:
        return "DOUBLE"
    return "VARCHAR"


def table_fields(table: str, keys: list[tuple], reserved: set[str]) -> list[Field]:
    """The columns of a table from its profiled keys (key, n, arrays, integers, decimals).

    A field and its multi-valued form (cs_version, cs_version{}) never occur in the same event, so they share a column.
    Fields that differ only in case (Signature from Sysmon, signature added by Splunk) are different fields:
    the all-lower-case one is Splunk's and is prefixed cim_.
    """
    groups: dict[str, list[tuple]] = {}
    for stat in keys:
        key = stat[0]
        if key in SPLUNK_FIELDS or SPLUNK_PATTERN.fullmatch(key):
            continue
        groups.setdefault(column_name(key, reserved) if key != "_raw" else "_raw", []).append(stat)
    fields = []
    for column, stats in sorted(groups.items()):
        spellings = {s[0].replace("{}", "") for s in stats}
        if len(spellings) > 1:
            splunk = [s for s in stats if s[0].replace("{}", "").islower()]
            others = [s for s in stats if s not in splunk]
            fields.append(Field(table, f"cim_{column.rstrip('_')}", column_type(splunk), [s[0] for s in splunk]))
            stats = others
        fields.append(Field(table, column, column_type(stats), [s[0] for s in stats]))
    names = [f.column for f in fields]
    if len(set(names)) != len(names):
        raise SystemExit(f"{DATASET}/{table}: duplicate columns {sorted({n for n in names if names.count(n) > 1})}")
    return sorted(fields, key=lambda f: f.column)


def read_fields() -> dict[str, list[Field]]:
    fields: dict[str, list[Field]] = {}
    with open(FIELDS, newline="") as f:
        for row in csv.DictReader(f):
            fields.setdefault(row["table"], []).append(Field(row["table"], row["column"], row["type"], row["keys"].split("|")))
    return fields


def write_fields(fields: dict[str, list[Field]]) -> None:
    with open(FIELDS, "w", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["table", "column", "type", "keys"])
        for table in TABLES:
            for field in fields.get(table, []):
                writer.writerow([table, field.column, field.type, "|".join(field.keys)])


def write_schema(fields: dict[str, list[Field]]) -> None:
    for sf in SCALE_FACTORS:
        directory = REPO_ROOT / DATASET / f"sf{sf}" / "schema"
        directory.mkdir(parents=True, exist_ok=True)
        for table in TABLES:
            if table not in fields:
                continue
            columns = ["    _time TIMESTAMPTZ NOT NULL"] + [f"    {f.column} {f.type}" for f in fields[table]]
            ddl = f"CREATE TABLE {DATASET}_sf{sf}.{table} (\n" + ",\n".join(columns) + "\n);\n"
            (directory / f"{table}.sql").write_text(ddl)
    log(f"{DATASET}: schema of SF {', '.join(map(str, SCALE_FACTORS))} written to the repo; review and commit it")


def extract_fields(con: duckdb.DuckDBPyConnection, tables: list[str]) -> None:
    fields = read_fields() if FIELDS.exists() else {}
    reserved = {k for (k,) in db.fetch_all(con, SQL_DIR / "reserved.sql")}
    for table in tables:
        log(f"{DATASET}/{table}: profiling fields")
        keys = db.fetch_all(con, SQL_DIR / "profile.sql", FILE=fetch(table))
        fields[table] = table_fields(table, keys, reserved)
    write_fields(fields)
    write_schema(fields)
    log(f"{DATASET}: fields.csv written to the repo; review and commit it")


def value(i: int) -> str:
    """The i-th extracted value as text, with a multi-valued field's values on separate lines."""
    return f"CASE json_type(v[{i}]) WHEN 'ARRAY' THEN array_to_string(CAST(v[{i}] AS VARCHAR[]), chr(10)) ELSE v[{i}] ->> '$' END"


def load(con: duckdb.DuckDBPyConnection, table: str, fields: list[Field]) -> None:
    keys = sorted({k for f in fields for k in f.keys} | {"_time", "_subsecond", "_bkt"})
    index = {k: i + 1 for i, k in enumerate(keys)}
    paths = "[" + ", ".join("'$.\"" + k.replace("'", "''") + "\"'" for k in keys) + "]"
    columns = ",\n       ".join(
        f"CAST(coalesce({', '.join(value(index[k]) for k in f.keys)}) AS {f.type}) AS {f.column}" for f in fields
    )
    events, no_time, haystack = db.fetch_all(
        con, SQL_DIR / "load.sql", FILE=fetch(table), PATHS=paths, COLUMNS=columns,
        TIME=index["_time"], SUBSECOND=index["_subsecond"], BUCKET=index["_bkt"],
    )[0]
    if no_time:
        raise SystemExit(f"{DATASET}/{table}: {no_time} events without a time")
    log(f"{DATASET}/{table}: {events:,} events, {events - haystack:,} of them in the attack-only set")


def rename(column: str, copy: int) -> str:
    return f"regexp_replace(regexp_replace({column}, '{HOST}', '\\1-{copy:03}', 'g'), '{ADDRESS}', '10.{copy}.\\1', 'g')"


def generate_table(con: duckdb.DuckDBPyConnection, exporter: Exporter, table: str, fields: list[Field], sf: int) -> None:
    export = exporter.table(table)
    if export.complete:
        return
    load(con, table, fields)
    columns = ["_time"] + [f.column for f in fields]
    db.execute(con, SQL_DIR / "original.sql", COLUMNS=", ".join(columns))
    export.write("_export", "copy 1", single_chunk=sf == 1)
    for copy in range(2, sf + 1):
        renamed = ["_time"] + [rename(f.column, copy) + f" AS {f.column}" if f.type == "VARCHAR" else f.column for f in fields]
        db.execute(con, SQL_DIR / "copy.sql", COPY=copy, COLUMNS=", ".join(renamed))
        export.write("_export", f"copy {copy}", single_chunk=False)
    export.finish()
    db.drop_table(con, "_export")
    db.drop_table(con, "_flat")


def generate(bucket: Bucket, args: argparse.Namespace) -> None:
    unknown = set(args.tables) - set(TABLES)
    if unknown:
        raise SystemExit(f"Unknown tables: {', '.join(sorted(unknown))}")
    if not 1 <= args.sf <= MAX_SF:
        raise SystemExit(f"--sf must be 1 to {MAX_SF}")
    prefix = f"{DATASET}/sf{args.sf}"
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    # On disk, since the largest table (Windows Security events) does not fit in memory; one file per scale factor,
    # so they can be generated in parallel
    con = db.connect(WORK_DIR / f"sf{args.sf}.duckdb")
    if args.extract_fields:
        extract_fields(con, args.tables)
        return
    publish_checked_in(bucket, prefix)
    if args.checked_in_only:
        return
    fields = read_fields()
    exporter = Exporter(con, bucket, prefix, args.target_mb)
    for table in args.tables:
        generate_table(con, exporter, table, fields[table], args.sf)
