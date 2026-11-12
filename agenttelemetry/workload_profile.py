"""Profile of the agenttelemetry workload, for the Profile section of agenttelemetry/README.md.

Run from the repo root; ROOT is the folder holding <table>/*.parquet, local or s3:// (SF1000 needs a large machine):

    uv run --with pytz python -m agenttelemetry.workload_profile measure --sf 1 --root temp/bucket/agenttelemetry/sf1
    uv run --with pytz python -m agenttelemetry.workload_profile shares --sf 1000 --root s3://sql-arena/agenttelemetry/sf1000
    uv run python -m agenttelemetry.workload_profile render

measure and shares append JSON lines to temp/agenttelemetry/profile/sf<N>.jsonl; render rewrites the README from them.

- Columns touched: the projections and filter columns of the table scans in the profiles of the queries.
- Distinct: count(DISTINCT col); the JSON text columns are counted by 64-bit hash to bound memory.
- Returned: rows of the result. Aggregated and joined: rows into aggregate and join operators.
- Scanned: rows of the parquet row groups each scan reads after min/max pruning on its filters, as DuckDB's own
  rows_scanned for parquet counts every row.
- Shares: the share of spans in the time window of each query.
"""

import argparse
import json
import math
import re
import threading
import time
from pathlib import Path

from common import REPO_ROOT, TEMP_DIR, db
from common.queries import load_queries

HERE = Path(__file__).parent
SQL = HERE / "sql"
README = HERE / "README.md"
OUT_DIR = TEMP_DIR / "agenttelemetry" / "profile"
SFS = [1, 10, 1000]
TABLES = ["spans", "traces", "scores", "tenants", "model_prices"]
HASHED = {"attributes", "input_text", "output_text"}
# Columns whose bucket data predates the generator's current scaling, with the growth the generator now gives
GROWTH_BY_DESIGN = {("traces", "user_id"): "square root"}
AGGREGATES = {"HASH_GROUP_BY", "PERFECT_HASH_GROUP_BY", "UNGROUPED_AGGREGATE"}
# DELIM_JOIN wrappers of decorrelated subqueries are left out, as the joins inside them are counted
JOINS = {"HASH_JOIN", "ASOF_JOIN", "NESTED_LOOP_JOIN", "PIECEWISE_MERGE_JOIN", "BLOCKWISE_NL_JOIN", "CROSS_PRODUCT",
         "IE_JOIN", "POSITIONAL_JOIN"}
COMPARISON = re.compile(r"^(\w+)\s*(>=|<=|=|>|<)\s*(.+?)(?:::.*)?$")
METRICS = [("returned", "Rows returned"), ("aggregated", "Rows aggregated"), ("scanned", "Rows scanned"),
           ("joined", "Rows joined")]

# The time window of each query that filters on time, and the README rows that group them
WINDOWS = {
    "q01": ("2025-10-28", "2025-10-29"), "q02": ("2025-10-27", "2025-10-30"), "q03": ("2025-12-31", "2026-01-01"),
    "q04": ("2025-12-02", "2026-01-01"), "q05": ("2025-12-25", "2026-01-01"), "q06": ("2025-12-31", "2026-01-01"),
    "q07": ("2025-11-01", "2025-12-01"), "q08": ("2025-07-01", "2025-10-01"), "q09": ("2025-12-25", "2026-01-01"),
    "q11": ("2025-10-06", "2025-10-13"), "q12": ("2025-12-02", "2026-01-01"), "q13": ("2025-02-01", "2025-03-01"),
    "q14": ("2025-12-15", "2025-12-16"), "q15": ("2025-12-25", "2026-01-01"),
    "q16": ("2025-12-31 15:00", "2025-12-31 16:00"), "q17": ("2025-12-25", "2026-01-01"),
    "q18": ("2025-03-01", "2025-04-01"), "q19": ("2025-09-02 12:00", "2025-09-02 18:00"),
    "q20": ("2025-10-01", "2026-01-01"), "q21": ("2025-11-01", "2025-12-01"), "q22": ("2025-12-02", "2026-01-01"),
    "q23": ("2025-10-01", "2026-01-01"), "q24": ("2025-12-25", "2026-01-01"), "q25": ("2025-06-24", "2025-07-08"),
    "q27": ("2025-12-01", "2026-01-01"), "q28": ("2025-07-08", "2025-07-11"), "q29": ("2025-12-25", "2026-01-01"),
    "q30": ("2025-12-25", "2026-01-01"), "q31": ("2025-12-25", "2026-01-01"), "q32": ("2025-12-25", "2026-01-01"),
}
WINDOW_ROWS = [
    ("1 hour", "Q16"), ("6 hours", "Q19"), ("1 day", "Q01, Q03, Q06, Q14"), ("3 days", "Q02 (of `traces`), Q28"),
    ("7 days", "Q05, Q09, Q11, Q15, Q17, Q24, Q29 to Q32"), ("14 days", "Q25"),
    ("a month or 30 days", "Q04, Q07, Q12, Q13, Q18, Q21, Q22, Q27"), ("a quarter", "Q08, Q20, Q23"),
    ("all", "Q10, Q26"),
]
WINDOW_INTRO = "Every scale factor has the same shares of `spans` in these windows, to within 0.2 percentage points:"

PROFILE_HEADING = "## Profile"
PROFILE_INTRO = """\
Measured with DuckDB 1.5 over the parquet in the bucket, with each table a view over `<table>/*.parquet`, by
`agenttelemetry/workload_profile.py`.
The distinct values of the columns are in the column tables of [Tables](#tables).
"""
QUERY_INTRO = """\
### Query Profile

From the profile of each query (`EXPLAIN ANALYZE`):

- **Rows returned:** rows of the result.
- **Rows aggregated:** rows into the aggregate operators: grouped, ungrouped and `count(DISTINCT)`.
- **Rows scanned:** rows of the parquet row groups each table scan reads, after skipping row groups by the min/max
  of its filters, summed over the scans of the query.
  DuckDB's own `rows_scanned` for parquet counts every row whatever the filter, so it is not used.
- **Rows joined:** rows into the join operators, both sides, summed over the joins of the query.
  In Q16 the recursive join counts every iteration.
"""


class Profiler:
    def __init__(self, sf: int, root: str, timeout: int):
        self.sf, self.root, self.timeout = sf, root.rstrip("/"), timeout
        self.ns = f"agenttelemetry_sf{sf}"
        self.out = OUT_DIR / f"sf{sf}.jsonl"
        self.out.parent.mkdir(parents=True, exist_ok=True)
        self.con = db.connect()
        if self.root.startswith("s3://"):
            db.execute(self.con, SQL / "profile_s3.sql")
        db.execute(self.con, SQL / "profile_setup.sql", NS=self.ns, ROOT=self.root)
        self.types = {t: dict(db.fetch_all(self.con, SQL / "profile_columns.sql", NS=self.ns, TABLE=t)) for t in TABLES}
        self.queries = load_queries(f"agenttelemetry/sf{sf}")

    def emit(self, record: dict) -> None:
        record["sf"] = self.sf
        with open(self.out, "a") as f:
            f.write(json.dumps(record) + "\n")
        print(json.dumps(record), flush=True)

    def timed(self, sql: str) -> list:
        """Run sql, interrupting it after the timeout."""
        timer = threading.Timer(self.timeout, self.con.interrupt)
        timer.start()
        try:
            return self.con.execute(sql).fetchall()
        finally:
            timer.cancel()

    def touched(self) -> dict[str, list[str]]:
        """From the profiles of the queries, as plain EXPLAIN does not name the files a scan reads."""
        used = {t: set() for t in TABLES}
        for sql in self.queries.values():
            plan = json.loads(self.con.execute("EXPLAIN (ANALYZE, FORMAT json) " + sql).fetchone()[1])
            for table, projections, filters in scans(plan):
                words = set(projections) | {w for f in filters for w in re.findall(r"\w+", f)}
                used[table] |= words & set(self.types[table])
        return {t: [c for c in self.types[t] if c in used[t]] for t in TABLES}

    def distinct(self) -> None:
        for table, columns in self.touched().items():
            for column in columns:
                expression = f"hash({column})" if column in HASHED else column
                start = time.time()
                try:
                    value = self.timed(db.read_sql(SQL / "profile_distinct.sql", NS=self.ns, TABLE=table,
                                                   EXPRESSION=expression))[0][0]
                except Exception as e:
                    value = failure(e)
                self.emit({"kind": "distinct", "table": table, "column": column, "value": value,
                           "seconds": round(time.time() - start, 1)})

    def scanned(self, table: str, filters: list[str]) -> int:
        keep = []
        for term in filters:
            m = COMPARISON.match(term)
            if not m or m.group(1) not in self.types[table]:
                continue
            column, op, literal = m.groups()
            typed = self.types[table][column]
            lo = f"CAST(any_value(min) FILTER (col = '{column}') AS {typed})"
            hi = f"CAST(any_value(max) FILTER (col = '{column}') AS {typed})"
            value = f"CAST({literal} AS {typed})"
            keep.append({">=": f"{hi} >= {value}", ">": f"{hi} > {value}", "<": f"{lo} < {value}",
                         "<=": f"{lo} <= {value}", "=": f"{lo} <= {value} AND {hi} >= {value}"}[op])
        having = " AND ".join(f"coalesce({k}, true)" for k in keep) or "true"
        return db.fetch_value(self.con, SQL / "profile_scanned.sql", TABLE=table, KEEP=having)

    def run_queries(self) -> None:
        for t in TABLES:
            db.execute(self.con, SQL / "profile_row_groups.sql", TABLE=t, ROOT=self.root)
        profile = OUT_DIR / f"sf{self.sf}.profile.json"
        for name, sql in self.queries.items():
            self.con.execute("SET enable_profiling = 'json'")
            self.con.execute(f"SET profiling_output = '{profile}'")
            start = time.time()
            try:
                rows = self.timed(sql)
            except Exception as e:
                self.con.execute("PRAGMA disable_profiling")
                self.emit({"kind": "query", "query": name, "error": failure(e), "detail": str(e)[:300],
                           "seconds": round(time.time() - start, 1)})
                continue
            seconds = round(time.time() - start, 1)
            self.con.execute("PRAGMA disable_profiling")
            plan = json.loads(profile.read_text())
            everything = list(nodes(plan))
            self.emit({"kind": "query", "query": name, "seconds": seconds, "returned": len(rows),
                       "aggregated": inputs(everything, AGGREGATES), "joined": inputs(everything, JOINS),
                       "scanned": sum(self.scanned(t, f) for t, _, f in scans(plan))})

    def shares(self) -> None:
        db.execute(self.con, SQL / "profile_span_hours.sql", NS=self.ns)
        for name, (start, end) in WINDOWS.items():
            share = db.fetch_value(self.con, SQL / "profile_share.sql", FROM=start, TO=end)
            self.emit({"kind": "share", "query": name, "percent": round(float(share) * 100, 4)})


def failure(e: Exception) -> str:
    return "timeout" if "INTERRUPT" in str(e).upper() else "error"


def nodes(node: dict):
    yield node
    for child in node.get("children", []):
        yield from nodes(child)


def inputs(everything: list[dict], operators: set[str]) -> int:
    return sum(c.get("operator_cardinality", 0) for n in everything if n.get("operator_type") in operators
               for c in n.get("children", []))


def as_list(value) -> list[str]:
    if value is None:
        return []
    items = value if isinstance(value, list) else [value]
    return [part.strip() for item in items for part in re.split(r"\n| AND ", item) if part.strip()]


def scans(plan: dict):
    """(table, projected columns, filter terms) of every parquet scan in a profile."""
    for n in nodes(plan):
        info = n.get("extra_info", {})
        if info.get("Function") != "READ_PARQUET":
            continue
        table = re.search(r"/(\w+)/\*\.parquet", info["Filename(s)"]).group(1)
        yield table, as_list(info.get("Projections")), as_list(info.get("Filters"))


def cell(value) -> str:
    if value is None:
        return ""
    return f"{value:,}" if isinstance(value, int) else str(value)


def percent(x: float) -> str:
    return f"{x:.2f}" if x < 1 else f"{x:.1f}" if x < 10 else f"{x:.0f}"


def align_tables(text: str) -> str:
    """Pad the cells of every Markdown table so its pipes line up in the source; numbers are right-aligned."""
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        if not lines[i].lstrip().startswith("|"):
            out.append(lines[i])
            i += 1
            continue
        j = i
        while j < len(lines) and lines[j].lstrip().startswith("|"):
            j += 1
        indent = lines[i][: len(lines[i]) - len(lines[i].lstrip())]
        rows = [[c.strip() for c in line.strip().strip("|").split("|")] for line in lines[i:j]]
        body = rows[2:]
        right = [rows[1][k].endswith(":") or all(re.fullmatch(r"[\d,.]+", r[k]) for r in body if r[k])
                 for k in range(len(rows[0]))]
        widths = [max([3] + [len(r[k]) for n, r in enumerate(rows) if n != 1]) for k in range(len(rows[0]))]
        for n, r in enumerate(rows):
            if n == 1:
                cells = ["-" * (w - 1) + ":" if a else "-" * w for w, a in zip(widths, right)]
            else:
                cells = [c.rjust(w) if a else c.ljust(w) for c, w, a in zip(r, widths, right)]
            out.append(indent + "| " + " | ".join(cells) + " |")
        i = j
    return "\n".join(out)


def render() -> None:
    records = [json.loads(line) for sf in SFS if (OUT_DIR / f"sf{sf}.jsonl").exists()
               for line in (OUT_DIR / f"sf{sf}.jsonl").read_text().splitlines() if line.strip()]
    distinct: dict[tuple[str, str], dict[int, int]] = {}
    queries: dict[str, dict[int, dict]] = {}
    shares: dict[str, list[float]] = {}
    for r in records:
        if r["kind"] == "distinct":
            distinct.setdefault((r["table"], r["column"]), {})[r["sf"]] = r["value"]
        elif r["kind"] == "query":
            queries.setdefault(r["query"], {})[r["sf"]] = r
        else:
            shares.setdefault(r["query"], []).append(r["percent"])

    header = " | ".join(f"SF{sf}" for sf in SFS)
    lines = [PROFILE_HEADING, "", PROFILE_INTRO, QUERY_INTRO, f"| Query | Metric | {header} |",
             "|---|---|" + "---:|" * len(SFS)]
    for name in sorted(queries):
        runs = queries[name]
        for key, label in METRICS:
            values = [None if sf not in runs else runs[sf]["error"] if "error" in runs[sf] else runs[sf][key]
                      for sf in SFS]
            lines.append(f"| {name.upper()} | {label} | " + " | ".join(cell(v) for v in values) + " |")

    text = README.read_text()
    head = text.split("\n" + PROFILE_HEADING + "\n")[0].rstrip("\n")
    if shares:
        head = render_windows(head, shares)
    head = render_distinct(head, distinct)
    README.write_text(align_tables(head + "\n\n" + "\n".join(lines)) + "\n")


def growth(counts: dict[int, int], by_design: str | None = None) -> str:
    """How a count grows with the scale factor, from the exponent between the smallest and largest SF measured."""
    if by_design:
        return by_design
    sfs = sorted(sf for sf, n in counts.items() if isinstance(n, int) and n > 0)
    if len(sfs) < 2:
        return ""
    exponent = math.log(counts[sfs[-1]] / counts[sfs[0]]) / math.log(sfs[-1] / sfs[0])
    if exponent < 0.02:
        return "constant"
    if exponent > 0.97:
        return "linear"
    if 0.45 <= exponent <= 0.55:
        return "square root"
    return f"sub-linear, about SF^{exponent:.2f}"


def render_distinct(text: str, distinct: dict[tuple[str, str], dict[int, int]]) -> str:
    """Put the distinct values at SF1 and how they grow after each column's type, in its table's section."""
    added = [f"Distinct SF{SFS[0]}", "Growth"]
    lines = text.split("\n")
    table = None
    for i, line in enumerate(lines):
        if line.startswith("### "):
            table = line[4:].strip()
        if table not in TABLES or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells[0] == "Column":
            keep = [k for k, c in enumerate(cells) if not (c.startswith("Distinct SF") or c == "Growth")]
            at = cells.index("Type") + 1
            values = added
        elif set(cells[0]) <= set("-:"):
            values = ["---:", "---"]
        else:
            column = cells[0].strip("`")
            counts = distinct.get((table, column), {})
            values = [cell(counts.get(SFS[0])), growth(counts, GROWTH_BY_DESIGN.get((table, column)))]
        kept = [cells[k] for k in keep]
        lines[i] = "| " + " | ".join(kept[:at] + values + kept[at:]) + " |"
    return "\n".join(lines)


def render_windows(text: str, shares: dict[str, list[float]]) -> str:
    """Replace the table of query windows and their share of spans, over every scale factor measured."""
    def span(queries: str) -> str:
        names = re.findall(r"Q\d\d", queries)
        if all(n.lower() not in WINDOWS for n in names):
            return "100%"
        xs = [x for n in names for x in shares.get(n.lower(), [])]
        lo, hi = percent(min(xs)), percent(max(xs))
        return f"{lo}%" if lo == hi else f"{lo} to {hi}%"

    table = [WINDOW_INTRO, "", "| Window | Queries | Share of spans |", "|---|---|---:|"]
    table += [f"| {window} | {queries} | {span(queries)} |" for window, queries in WINDOW_ROWS]
    start = text.index(WINDOW_INTRO)
    end = text.index("\n\n", start + len(WINDOW_INTRO) + 2)
    return text[:start] + "\n".join(table) + text[end:]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("step", choices=["measure", "shares", "render"])
    parser.add_argument("--sf", type=int)
    parser.add_argument("--root", help="folder holding <table>/*.parquet, local or s3://")
    parser.add_argument("--timeout", type=int, default=3600, help="seconds before a count or query is interrupted")
    args = parser.parse_args()
    if args.step == "render":
        render()
        return
    if args.sf is None or args.root is None:
        parser.error(f"{args.step} needs --sf and --root")
    profiler = Profiler(args.sf, args.root, args.timeout)
    if args.step == "measure":
        profiler.distinct()
        profiler.run_queries()
    else:
        profiler.shares()


if __name__ == "__main__":
    main()
