"""DuckDB access. SQL lives in .sql files whose %%NAME%% placeholders are filled from keyword arguments."""

import json
import os
import zipfile
from pathlib import Path

import duckdb
import pyarrow.parquet as pq

from common import TEMP_DIR

SQL_DIR = Path(__file__).parent / "sql"
ROW_GROUP_ROWS = 122_880


def connect(database: str | Path = ":memory:", temp_dir: Path = TEMP_DIR / "duckdb_tmp") -> duckdb.DuckDBPyConnection:
    """DUCKDB_MEMORY_LIMIT (e.g. 60GB) caps DuckDB's memory, for parallel generators on one machine."""
    temp_dir.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(database))
    con.execute(f"SET temp_directory = '{temp_dir}'")
    if limit := os.environ.get("DUCKDB_MEMORY_LIMIT"):
        con.execute(f"SET memory_limit = '{limit}'")
    return con


def read_sql(path: Path, **params: object) -> str:
    sql = path.read_text()
    for name, value in params.items():
        sql = sql.replace(f"%%{name}%%", str(value))
    return sql


def execute(con: duckdb.DuckDBPyConnection, path: Path, **params: object) -> None:
    con.execute(read_sql(path, **params))


def fetch_all(con: duckdb.DuckDBPyConnection, path: Path, **params: object) -> list[tuple]:
    return con.execute(read_sql(path, **params)).fetchall()


def fetch_value(con: duckdb.DuckDBPyConnection, path: Path, **params: object) -> object:
    return con.execute(read_sql(path, **params)).fetchone()[0]


def parse(con: duckdb.DuckDBPyConnection, query: str) -> dict:
    """The parse tree of a query, as produced by json_serialize_sql."""
    return json.loads(con.execute(read_sql(SQL_DIR / "serialize_sql.sql"), [query]).fetchone()[0])


def tables(con: duckdb.DuckDBPyConnection, schema: str) -> list[str]:
    return [name for (name,) in fetch_all(con, SQL_DIR / "tables.sql", SCHEMA=schema)]


def drop_table(con: duckdb.DuckDBPyConnection, table: str) -> None:
    execute(con, SQL_DIR / "drop_table.sql", TABLE=table)


def row_count(con: duckdb.DuckDBPyConnection, table: str) -> int:
    return fetch_value(con, SQL_DIR / "row_count.sql", TABLE=table)


def row_range(table: str, start: int, end: int) -> str:
    """A source for write_parquet/write_part: rows start..end-1 of a table, in insertion order."""
    return read_sql(SQL_DIR / "row_range.sql", TABLE=table, START=start, END=end)


def write_parquet(con: duckdb.DuckDBPyConnection, source: str, path: Path) -> None:
    """Write a table (or a parenthesised query) as parquet with statistics and a page index on every column.

    DuckDB's own writer has no page index, so its result is streamed into the pyarrow writer.
    """
    reader = con.execute(read_sql(SQL_DIR / "select_all.sql", SOURCE=source)).to_arrow_reader(ROW_GROUP_ROWS)
    with pq.ParquetWriter(path, reader.schema, write_statistics=True, write_page_index=True) as writer:
        for batch in reader:
            writer.write_batch(batch, row_group_size=ROW_GROUP_ROWS)


def write_part(con: duckdb.DuckDBPyConnection, source: str, out_dir: Path, stem: str) -> list[Path]:
    """Write a table (or a parenthesised query) as <stem>.parquet and <stem>.csv.zip in out_dir."""
    out_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = out_dir / f"{stem}.parquet"
    csv_path = out_dir / f"{stem}.csv"
    zip_path = out_dir / f"{stem}.csv.zip"
    write_parquet(con, source, parquet_path)
    execute(con, SQL_DIR / "write_csv.sql", SOURCE=source, CSV=csv_path)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(csv_path, csv_path.name)
    csv_path.unlink()
    return [parquet_path, zip_path]
