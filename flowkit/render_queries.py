"""One-off extraction of the FlowKit query set, kept so the committed queries can be reproduced.

Stage 1 renders FlowAPI query specs to Postgres SQL with flowmachine, against a FlowDB test container:

    docker run -d --name flowdb-testdata -p 9000:5432 -e POSTGRES_USER=flowdb -e POSTGRES_PASSWORD=flowflow \\
        -e FLOWMACHINE_FLOWDB_USER=flowmachine -e FLOWMACHINE_FLOWDB_PASSWORD=foo -e FLOWAPI_FLOWDB_USER=flowapi -e FLOWAPI_FLOWDB_PASSWORD=foo \\
        --shm-size 1G flowminder/flowdb-testdata:1.34.0
    docker run -d --name flowmachine-redis -p 6379:6379 redis:7-alpine redis-server --requirepass fm_redis
    uv run --no-project --python 3.12 --with-requirements flowkit/render_requirements.txt \\
        python flowkit/render_queries.py render

The specs are in query_specs.py. Rendered SQL goes to temp/flowkit/rendered/.

Stage 2 rewrites the rendered SQL to portable SQL over the flowkit_sf<N> namespace:

    uv run flowkit/render_queries.py rewrite --sf 1
"""

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMMIT = "24d88247d57987fe33f6b8915540d7bf09b58033"
RENDERED_DIR = ROOT / "temp" / "flowkit" / "rendered"
SOURCE_SCHEMAS = {"events", "infrastructure", "geography"}

LICENCE = (
    "Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit {commit})\n"
    "and rewritten to portable SQL for SQL Arena.\n"
    "This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of\n"
    "the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/."
)


def render(specs: dict[str, dict], out_dir: Path) -> None:
    import flowmachine
    from flowmachine.core.server.query_schemas import FlowmachineQuerySchema

    flowmachine.connect(
        flowdb_host="localhost", flowdb_port=9000, flowdb_user="flowdb", flowdb_password="flowflow",
        redis_host="localhost", redis_port=6379, redis_password="fm_redis",
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    failed = []
    for name, spec in specs.items():
        try:
            query = FlowmachineQuerySchema().load(spec)._flowmachine_query_obj
            sql = query.get_query()
        except Exception as e:
            failed.append(name)
            print(f"FAILED {name}: {spec['query_kind']}: {type(e).__name__}: {e}")
            continue
        (out_dir / f"{name}.sql").write_text(sql)
        (out_dir / f"{name}.json").write_text(json.dumps(spec, indent=2))
        print(f"rendered {name}: {spec['query_kind']}")
    if failed:
        raise SystemExit(f"{len(failed)} specs failed: {', '.join(failed)}")


def load_schema(schema_dir: Path) -> dict[str, set[str]]:
    """Table name -> column names, from the checked-in CREATE TABLE files."""
    import sqlglot
    from sqlglot import exp

    tables = {}
    for path in schema_dir.glob("*.sql"):
        create = sqlglot.parse_one(path.read_text(), read="duckdb")
        if isinstance(create, exp.Create):
            tables[create.this.this.name] = {c.name for c in create.this.expressions if isinstance(c, exp.ColumnDef)}
    return tables


def rewrite_sql(sql: str, namespace: str, schema: dict[str, set[str]]) -> str:
    import sqlglot
    from sqlglot import exp
    from sqlglot.transforms import eliminate_distinct_on

    tree = sqlglot.parse_one(sql, read="postgres")
    tree = tree.transform(lambda node: _region_join(node, namespace))
    tree = tree.transform(_open_service_interval)
    tree = tree.transform(lambda node: _qualify(node, namespace))
    tree = tree.transform(_radius_of_gyration)
    tree = tree.transform(lambda node: _distance_matrix(node, namespace))
    tree = tree.transform(lambda node: _prune_columns(node, namespace, schema))
    tree = _prune_passthrough(tree, namespace, schema)
    tree = tree.transform(_point_coordinates)
    tree = tree.transform(_time_of_day)
    tree = tree.transform(_date_trunc)
    tree = tree.transform(_inline_windows)
    tree = tree.transform(_mode)
    tree = _histogram(tree)
    tree = tree.transform(eliminate_distinct_on)
    if tree.find(exp.TimeToStr):
        raise ValueError(f"to_char left after rewrite: {tree.find(exp.TimeToStr).sql()}")
    leftover = {f.sql_name() if not isinstance(f, exp.Anonymous) else f.name for f in tree.find_all(exp.Func)}
    postgis = sorted(n for n in leftover if n.lower().startswith("st_"))
    if postgis:
        raise ValueError(f"PostGIS functions left after rewrite: {postgis}")
    return tree.sql(pretty=True)


EARTH_RADIUS_M = 6371008.8


def _haversine(lon1: str, lat1: str, lon2: str, lat2: str):
    """Great circle distance in metres; replaces PostGIS st_distance over geography (spheroid, ~0.1% apart here)."""
    import sqlglot

    return sqlglot.parse_one(
        f"2 * {EARTH_RADIUS_M} * ASIN(SQRT(POWER(SIN(RADIANS({lat2} - {lat1}) / 2), 2)"
        f" + COS(RADIANS({lat1})) * COS(RADIANS({lat2})) * POWER(SIN(RADIANS({lon2} - {lon1}) / 2), 2)))"
    )


def _projects(select, name: str) -> bool:
    from sqlglot import exp

    return any(isinstance(e, (exp.Alias, exp.Column)) and e.alias_or_name == name for e in select.expressions)


def _radius_of_gyration(node):
    """RadiusOfGyration collects points with array_agg and unnests them again; use window averages instead."""
    import sqlglot
    from sqlglot import exp

    if not isinstance(node, exp.Select) or not any(d.parent_select is node for d in node.find_all(exp.StDistance)):
        return node
    unnested = node.args["from_"].this.this
    if not (isinstance(unnested, exp.Select) and _projects(unnested, "point")):
        return node
    aggregated = unnested.args["from_"].this.this
    if not _projects(aggregated, "points"):
        raise ValueError("unexpected RadiusOfGyration shape")
    locations = aggregated.args["from_"].this
    alias = locations.alias
    distance = _haversine("lon", "lat", "av_lon", "av_lat").sql()
    return sqlglot.parse_one(
        f"SELECT subscriber, SQRT(AVG(POWER({distance}, 2))) / 1000 AS value"
        f" FROM (SELECT {alias}.subscriber AS subscriber, lon, lat,"
        f" AVG(lon) OVER (PARTITION BY {alias}.subscriber) AS av_lon,"
        f" AVG(lat) OVER (PARTITION BY {alias}.subscriber) AS av_lat"
        f" FROM {locations.sql()}) AS located GROUP BY subscriber"
    )


def _distance_matrix(node, namespace: str):
    """DistanceMatrix measures every pair of distinct cell points with PostGIS; use coordinates and haversine."""
    import sqlglot
    from sqlglot import exp

    if not (isinstance(node, exp.Select) and _projects(node, "lon_from") and _projects(node, "value")):
        return node
    if not any(f.name.lower() == "st_x" for f in node.find_all(exp.Anonymous)):
        return node
    points = f"(SELECT longitude, latitude FROM {namespace}.cells GROUP BY longitude, latitude)"
    distance = _haversine("a.longitude", "a.latitude", "b.longitude", "b.latitude").sql()
    return sqlglot.parse_one(
        "SELECT a.longitude AS lon_from, a.latitude AS lat_from, b.longitude AS lon_to, b.latitude AS lat_to,"
        f" {distance} / 1000 AS value FROM {points} AS a CROSS JOIN {points} AS b"
    )


def _date_trunc(node):
    """sqlglot reads date_trunc('hour', t) as TimestampTrunc; write it back as DATE_TRUNC, not TIMESTAMP_TRUNC."""
    from sqlglot import exp

    if not isinstance(node, exp.TimestampTrunc):
        return node
    return exp.Anonymous(this="DATE_TRUNC", expressions=[exp.Literal.string(node.text("unit").lower()), node.this])


def _inline_windows(node):
    """Replace named windows (WINDOW w AS (...)) by their definition, and name unaliased window columns like Postgres."""
    from sqlglot import exp

    if not isinstance(node, exp.Select):
        return node
    windows = {w.this.name: w for w in node.args.get("windows") or []}
    if windows:
        for window in node.find_all(exp.Window):
            name = window.args.get("alias")
            if name is not None and name.name in windows and window.parent_select is node:
                definition = windows[name.name]
                window.set("alias", None)
                window.set("partition_by", [p.copy() for p in definition.args.get("partition_by") or []])
                window.set("order", definition.args["order"].copy() if definition.args.get("order") else None)
        node.set("windows", None)
    node.set("expressions", [
        e.as_(e.this.sql_name().lower()) if isinstance(e, exp.Window) else e for e in node.expressions
    ])
    return node


def _mode(node):
    """SELECT g, mode() WITHIN GROUP (ORDER BY x) ... GROUP BY g becomes the most frequent x per g, ties to the lowest."""
    import sqlglot
    from sqlglot import exp

    if not isinstance(node, exp.Select):
        return node
    modes = [w for w in node.find_all(exp.WithinGroup) if w.this.name.lower() == "mode" and w.parent_select is node]
    if not modes:
        return node
    if len(modes) > 1 or not node.args.get("group"):
        raise ValueError(f"unexpected mode(): {node.sql()[:200]}")
    within = modes[0]
    target = within.parent if isinstance(within.parent, exp.Column) else within
    value = within.expression.expressions[0].this
    alias = target.parent.alias if isinstance(target.parent, exp.Alias) else "mode"
    groups = [g.sql() for g in node.args["group"].expressions]
    others = [e for e in node.expressions if e.unalias() is not target]
    inner = node.copy()
    inner.set("expressions", [e.copy() for e in others] + [value.copy().as_(alias), sqlglot.parse_one(
        f"ROW_NUMBER() OVER (PARTITION BY {', '.join(groups)} ORDER BY COUNT(*) DESC, {value.sql()}) AS mode_rank")])
    inner.set("group", exp.Group(expressions=[*[g.copy() for g in node.args["group"].expressions], value.copy()]))
    names = [e.alias_or_name for e in others] + [alias]
    return sqlglot.parse_one(f"SELECT {', '.join(names)} FROM ({inner.sql()}) AS modal WHERE mode_rank = 1")


def _histogram(tree):
    """HistogramAggregation bins with numrange and generate_series; use lower/upper columns and a VALUES list."""
    import sqlglot
    from sqlglot import exp

    for breaks in [c for c in tree.find_all(exp.CTE) if c.alias == "breaks"]:
        select = breaks.this
        series = select.find(exp.ExplodingGenerateSeries)
        bins = int(series.args["end"].name)
        values = ", ".join(f"({v})" for v in range(1, bins + 1))
        series.parent.replace(sqlglot.parse_one(f"SELECT * FROM (VALUES {values}) AS v(v)").args["from_"].this)
        select.set("expressions", [exp.column("lower"), exp.column("upper"), exp.column("v")])
        hist = next(c for c in tree.find_all(exp.CTE) if c.alias == "hist").this
        for f in list(hist.find_all(exp.Lower, exp.Upper)):
            if isinstance(f.this, exp.Column) and f.this.name == "bin":
                f.replace(exp.column("lower" if isinstance(f, exp.Lower) else "upper", table="breaks"))
        for contains in list(hist.find_all(exp.ArrayContainsAll)):
            x = contains.expression.sql()
            contains.replace(sqlglot.parse_one(
                f"({x} >= breaks.lower AND ({x} < breaks.upper OR (breaks.v = {bins} AND {x} <= breaks.upper)))"))
        hist.set("group", exp.Group(expressions=[exp.column(c, table="breaks") for c in ("lower", "upper", "v")]))
        hist.set("order", exp.Order(expressions=[exp.Ordered(this=exp.column("lower", table="breaks"))]))
    return tree


def _qualify(node, namespace: str):
    from sqlglot import exp

    if isinstance(node, exp.Table) and node.db in SOURCE_SCHEMAS:
        node.set("db", exp.to_identifier(namespace))
    elif isinstance(node, exp.Column) and node.db in SOURCE_SCHEMAS:
        node.set("db", exp.to_identifier(namespace))
    return node


def _prune_columns(node, namespace: str, schema: dict[str, set[str]]):
    """Drop columns FlowDB has but our table lacks from SELECT lists over one table, adding lon/lat next to geom_point."""
    from sqlglot import exp

    if not isinstance(node, exp.Select) or node.args.get("joins"):
        return node
    source = node.args.get("from_") or node.args.get("from")
    table = source.this if source else None
    if not isinstance(table, exp.Table) or table.db != namespace:
        return node
    columns = schema[table.name]
    kept = [e for e in node.expressions if not isinstance(e.unalias(), exp.Column) or e.unalias().name in columns]
    names = {e.unalias().name for e in kept if isinstance(e.unalias(), exp.Column)}
    if "geom_point" in names:
        kept += [exp.column(c) for c in ("longitude", "latitude") if c not in names]
    node.set("expressions", kept)
    return node


def _prune_passthrough(tree, namespace: str, schema: dict[str, set[str]]):
    """Drop pass-through columns (alias.column) that a joined table or subquery no longer provides, innermost first."""
    from sqlglot import exp

    for select in reversed(list(tree.find_all(exp.Select))):
        sources = [select.args["from_"].this] if select.args.get("from_") else []
        sources += [j.this for j in select.args.get("joins") or []]
        provided = {}
        for source in sources:
            if isinstance(source, exp.Table) and source.db == namespace:
                provided[source.alias_or_name] = schema[source.name]
            elif isinstance(source, exp.Subquery) and isinstance(source.this, exp.Select):
                names = [e.alias_or_name for e in source.this.expressions]
                if "*" not in names:
                    provided[source.alias] = set(names)
        select.set("expressions", [
            e for e in select.expressions
            if not (isinstance(e.unalias(), exp.Column) and not isinstance(e.unalias().this, exp.Star)
                    and e.unalias().table in provided
                    and e.unalias().name not in provided[e.unalias().table])
        ])
    return tree


def _point_coordinates(node):
    """st_x / st_y of a cell or site geom_point become its longitude / latitude column."""
    from sqlglot import exp

    if not isinstance(node, exp.Anonymous) or node.name.lower() not in ("st_x", "st_y"):
        return node
    point = node.expressions[0].find(exp.Column)
    if point is None or point.name != "geom_point":
        raise ValueError(f"unexpected {node.name}: {node.sql()}")
    return exp.column("longitude" if node.name.lower() == "st_x" else "latitude", table=point.table)


def _time_of_day(node):
    """to_char(t, 'HH24:MI') <op> 'hh:mm' becomes a comparison of minutes since midnight."""
    from sqlglot import exp

    if not isinstance(node, (exp.EQ, exp.NEQ, exp.GT, exp.GTE, exp.LT, exp.LTE)):
        return node
    left, right = node.this, node.expression
    if not isinstance(left, exp.TimeToStr) or not (isinstance(right, exp.Literal) and right.is_string):
        return node
    if left.text("format") != "%H:%M":
        raise ValueError(f"unexpected time format: {left.sql()}")
    hours, minutes = (int(p) for p in right.this.split(":"))
    value = left.this
    since_midnight = exp.Add(
        this=exp.Mul(this=exp.Extract(this=exp.var("HOUR"), expression=value.copy()), expression=exp.Literal.number(60)),
        expression=exp.Extract(this=exp.var("MINUTE"), expression=value.copy()),
    )
    return type(node)(this=exp.paren(since_midnight), expression=exp.Literal.number(hours * 60 + minutes))


def _region_join(node, namespace: str):
    """Replace JOIN (... FROM geography.adminN) AS g ON st_within(cells.geom_point, g.geom) by a cell_region join."""
    from sqlglot import exp

    if not isinstance(node, exp.Join):
        return node
    on = node.args.get("on")
    within = next((f for f in on.find_all(exp.Anonymous) if f.name.lower() == "st_within"), None) if on else None
    if within is None:
        return node
    point = within.expressions[0].find(exp.Column)
    if point is None or point.name != "geom_point":
        raise ValueError(f"unexpected st_within join: {on.sql()}")
    alias = node.this.alias_or_name
    region = exp.to_table(f"{namespace}.cell_region").as_(alias)
    condition = exp.column("id", table=point.table).eq(exp.column("location_id", table=alias))
    return exp.Join(this=region, kind=node.args.get("kind"), side=node.args.get("side"), on=condition)


def _infinite(node) -> bool:
    from sqlglot import exp

    if isinstance(node, exp.Cast):
        node = node.this
    return isinstance(node, exp.Literal) and node.this in ("infinity", "-infinity")


def _open_service_interval(node):
    """x BETWEEN COALESCE(a, '-infinity') AND COALESCE(b, 'infinity') becomes NULL tolerant comparisons."""
    from sqlglot import exp

    if not isinstance(node, exp.Between):
        return node
    bounds = [node.args["low"], node.args["high"]]
    if not all(isinstance(b, exp.Coalesce) and _infinite(b.expressions[-1]) for b in bounds):
        return node
    low, high = (b.this for b in bounds)
    value = node.this
    return exp.paren(
        exp.or_(low.copy().is_(exp.null()), exp.GTE(this=value.copy(), expression=low.copy()))
    ).and_(exp.paren(exp.or_(high.copy().is_(exp.null()), exp.LTE(this=value.copy(), expression=high.copy()))))


def rewrite(in_dir: Path, out_dir: Path, namespace: str, schema: dict[str, set[str]]) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for path in sorted(in_dir.glob("*.sql")):
        spec_path = path.with_suffix(".json")
        spec = json.loads(spec_path.read_text()) if spec_path.exists() else None
        title = f"FlowKit {path.stem.upper()}: {spec['query_kind']}" if spec else f"FlowKit {path.stem}"
        header = [title, "", LICENCE.format(commit=COMMIT)]
        if spec:
            header += ["", "FlowAPI query spec:", json.dumps(spec)]
        body = rewrite_sql(path.read_text(), namespace, schema)
        comment = "/* " + "\n   ".join(line for line in "\n".join(header).splitlines()) + " */"
        (out_dir / path.name).write_text(f"{comment}\n{body};\n")
        print(f"rewrote {path.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="stage", required=True)
    sub.add_parser("render")
    rw = sub.add_parser("rewrite")
    rw.add_argument("--sf", default="1")
    rw.add_argument("--input", type=Path, default=RENDERED_DIR)
    rw.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.stage == "render":
        from query_specs import SPECS  # flowkit/query_specs.py, next to this script

        render(SPECS, RENDERED_DIR)
    else:
        scale = ROOT / "flowkit" / f"sf{args.sf}"
        rewrite(args.input, args.output or scale / "queries", f"flowkit_sf{args.sf}", load_schema(scale / "schema"))


if __name__ == "__main__":
    sys.exit(main())
