"""Checked-in files: query sets at <dataset path>/queries/<name>.sql and DDL at <dataset path>/schema/<table>.sql.

Both are uploaded unchanged to the same key in the bucket.
"""

from pathlib import Path

import duckdb

from common import REPO_ROOT, db, log
from common.bucket import Bucket

CHECKED_IN = ("queries", "schema")


def query_dir(prefix: str) -> Path:
    return REPO_ROOT / prefix / "queries"


def publish_checked_in(bucket: Bucket, prefix: str) -> None:
    """Upload the checked-in queries and schema of a dataset path."""
    for folder in CHECKED_IN:
        files = sorted((REPO_ROOT / prefix / folder).glob("*.sql"))
        if not files:
            log(f"{prefix}: no checked-in {folder} to publish")
            continue
        bucket.put_files([(f, f"{prefix}/{folder}/{f.name}") for f in files], keep=True).result()
        log(f"{prefix}/{folder}: {len(files)} files uploaded")


def _base_tables(node: object) -> list[dict]:
    if isinstance(node, dict):
        found = [node] if node.get("type") == "BASE_TABLE" else []
        return found + [t for v in node.values() for t in _base_tables(v)]
    if isinstance(node, list):
        return [t for v in node for t in _base_tables(v)]
    return []


def _cte_names(node: object) -> set[str]:
    if isinstance(node, dict):
        names = {entry["key"] for entry in node.get("cte_map", {}).get("map", [])}
        return names.union(*(_cte_names(v) for v in node.values()))
    if isinstance(node, list):
        return set().union(*(_cte_names(v) for v in node))
    return set()


def qualify(con: duckdb.DuckDBPyConnection, query: str, namespace: str, tables: set[str]) -> str:
    """Prefix every reference to one of tables with namespace, at the positions DuckDB's parser reports."""

    def references(tree: dict) -> list[dict]:
        ctes = _cte_names(tree)
        return [t for t in _base_tables(tree) if t["table_name"] in tables and t["table_name"] not in ctes]

    tree = db.parse(con, query)
    if tree.get("error"):
        raise ValueError(tree.get("error_message"))
    before = references(tree)
    # query_location is a byte offset into the UTF-8 text
    text = query.encode()
    for location in sorted({t["query_location"] for t in before if not t["schema_name"]}, reverse=True):
        text = text[:location] + namespace.encode() + b"." + text[location:]
    query = text.decode()
    after = references(db.parse(con, query))
    if sorted(t["table_name"] for t in after) != sorted(t["table_name"] for t in before):
        raise ValueError("table references changed while qualifying")
    if any(t["schema_name"] != namespace for t in after):
        raise ValueError(f"tables left unqualified: {[t['table_name'] for t in after if t['schema_name'] != namespace]}")
    return query


def write_queries(prefix: str, tables: set[str], queries: dict[str, tuple[str, str]]) -> None:
    """Write {name: (title, query)} to the repo, replacing the existing query set of prefix."""
    directory = query_dir(prefix)
    directory.mkdir(parents=True, exist_ok=True)
    for old in directory.glob("*.sql"):
        old.unlink()
    con = db.connect()
    namespace = prefix.replace("/", "_")
    for name, (title, query) in queries.items():
        qualified = qualify(con, query.strip(), namespace, tables)
        (directory / f"{name}.sql").write_text(f"/* {title} */\n{qualified}\n")
    log(f"{prefix}/queries: {len(queries)} queries written to the repo; review and commit them")
