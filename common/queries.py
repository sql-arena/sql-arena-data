"""Checked-in files: query sets at <dataset path>/queries/<name>.sql and DDL at <dataset path>/schema/<table>.sql.

The repo is authoritative: both are uploaded unchanged to the same key in the bucket, only once committed, and
files the repo no longer has are removed from the bucket. A dataset whose queries are the same at every scale
factor may instead keep one template at <dataset>/queries/<name>.sql, with %%NAMESPACE%% for the namespace; it is
uploaded to <dataset path>/queries/ with the namespace filled in.
"""

import subprocess
from pathlib import Path

import duckdb

from common import REPO_ROOT, TEMP_DIR, db, log
from common.bucket import Bucket

CHECKED_IN = ("queries", "schema")
NAMESPACE = "%%NAMESPACE%%"


def query_dir(prefix: str) -> Path:
    return REPO_ROOT / prefix / "queries"


def template_dir(prefix: str) -> Path | None:
    """The query template of the dataset of prefix, <dataset>/queries/, when it has one instead of per-path queries."""
    dataset = prefix.split("/")[0]
    directory = REPO_ROOT / dataset / "queries"
    if dataset == prefix or not directory.is_dir():
        return None
    if query_dir(prefix).is_dir():
        raise SystemExit(f"{prefix}: has both {dataset}/queries/ and {prefix}/queries/; keep one")
    return directory


def load_queries(prefix: str) -> dict[str, str]:
    """{name: sql} of a dataset path, with a template's %%NAMESPACE%% replaced by the path's namespace."""
    template = template_dir(prefix)
    if template is None:
        return {f.stem: f.read_text() for f in sorted(query_dir(prefix).glob("*.sql"))}
    namespace = prefix.replace("/", "_")
    queries = {f.stem: f.read_text() for f in sorted(template.glob("*.sql"))}
    missing = [name for name, sql in queries.items() if NAMESPACE not in sql]
    if missing:
        raise SystemExit(f"{template}: no {NAMESPACE} in {', '.join(missing)}")
    return {name: sql.replace(NAMESPACE, namespace) for name, sql in queries.items()}


def publish_checked_in(bucket: Bucket, prefix: str) -> None:
    """Upload the committed queries and schema of a dataset path, and remove bucket files the repo doesn't have.

    Uncommitted changes stop an upload to the bucket. A test run with --no-upload publishes the working tree.
    """
    template = template_dir(prefix)
    if bucket.upload:
        paths = [f"{prefix}/{folder}" for folder in CHECKED_IN] + ([str(template)] if template else [])
        changed = subprocess.run(["git", "status", "--porcelain", "--", *paths], cwd=REPO_ROOT,
                                 capture_output=True, text=True, check=True).stdout
        if changed:
            raise SystemExit(f"{prefix}: commit the queries and schema before uploading them:\n{changed}")
    for folder in CHECKED_IN:
        if folder == "queries" and template:
            files = _render_template(prefix)
        else:
            files = sorted((REPO_ROOT / prefix / folder).glob("*.sql"))
        if not files:
            log(f"{prefix}: no checked-in {folder} to publish")
            continue
        bucket.put_files([(f, f"{prefix}/{folder}/{f.name}") for f in files], keep=True).result()
        stale = sorted(set(bucket.keys(f"{prefix}/{folder}")) - {f"{prefix}/{folder}/{f.name}" for f in files})
        bucket.delete(stale)
        log(f"{prefix}/{folder}: {len(files)} files uploaded" + (f", {len(stale)} removed" if stale else ""))


def _render_template(prefix: str) -> list[Path]:
    """The template queries of prefix, written with its namespace to temp/<prefix>/queries/."""
    directory = TEMP_DIR / prefix / "queries"
    directory.mkdir(parents=True, exist_ok=True)
    for old in directory.glob("*.sql"):
        old.unlink()
    files = []
    for name, sql in load_queries(prefix).items():
        path = directory / f"{name}.sql"
        path.write_text(sql)
        files.append(path)
    return files


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
