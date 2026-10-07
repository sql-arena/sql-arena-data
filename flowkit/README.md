# FlowKit CDR

Synthetic mobile operator call detail records (CDR) in the schema of
[Flowminder FlowKit](https://github.com/Flowminder/FlowKit), with a query set rendered by FlowKit's
`flowmachine`. Flowminder uses FlowKit to analyse real operator CDRs for humanitarian work. That gives
the dataset a real-world query workload over data we can generate at any scale.

Status: in progress. There is no generator or query set yet. Research notes are in
[CANDIDATE_DATASETS.md](../CANDIDATE_DATASETS.md#cdr-query-sets).

## Licence

FlowKit is [MPL-2.0](https://mozilla.org/MPL/2.0/). Query files extracted from it keep the MPL-2.0
notice. The generated data is synthetic.

Upstream version: FlowKit `master` at commit `24d88247d57987fe33f6b8915540d7bf09b58033`
(2026-05-28; the latest release is 1.34.0). Pin the commit used for extraction here.

## Source schema

From [`flowdb/bin/build/0020_schema_events.sql`](https://github.com/Flowminder/FlowKit/blob/master/flowdb/bin/build/0020_schema_events.sql)
and the `infrastructure` and `geography` schemas next to it:

- `events.calls`, `events.sms`, `events.mds` (mobile data sessions), `events.topups`, `events.forwards`.
  Each row is one leg of an event, with `msisdn`, `msisdn_counterpart`, `outgoing`, `datetime`, `duration`,
  `location_id` (the cell), `imsi`, `imei`, `tac` (handset model) and operator/country codes.
- `infrastructure.cells`, `infrastructure.sites`, `infrastructure.tacs`.
- `geography.admin0` to `admin3`: administrative regions (PostGIS polygons).

Our tables keep FlowKit's table and column names so the rendered queries need as few changes as possible.
Types are limited to the Iceberg-compatible set in the root README. Geometry is replaced by a
`cell_region` mapping table (cell id to admin pcodes) plus WKT/lon/lat columns.

## Generation plan

The data generator is a DuckDB SQL port of FlowKit's
[`generate_synthetic_data_sql.py`](https://github.com/Flowminder/FlowKit/blob/master/flowdb/testdata/bin/generate_synthetic_data_sql.py).
That script scales by subscribers, cells, sites, TACs, calls/SMS/MDS per day and days. It models
home regions, out-of-area and relocation probabilities, an interaction graph and an optional
"disaster" displacement.

Changes from upstream:

- Deterministic: hash-based randomness seeded by row ids instead of `random()`, so every run and scale
  factor is reproducible.
- Scales by subscribers x days, generated one day at a time so runs restart from the last finished day,
  and exported through the shared 500 MB parquet exporter sorted by `datetime`.
- No PostGIS: regions come from a fixed, checked-in boundary set and cells are assigned to regions at generation time.

## Query plan

The queries are rendered once with `flowmachine`, by building each query object with fixed parameters
and calling `get_query()` against a FlowDB test container (`flowminder/flowdb-testdata`). Upstream checks
in only 16 rendered snapshots (`*_sql.approved.txt`, mostly `daily_location` and `event_count`).

The rendered SQL is then rewritten for portability:

- PostGIS `st_within` cell-to-region joins become joins to `cell_region`.
- Postgres-only syntax (`DISTINCT ON`, `::` casts) becomes standard SQL.
- Tables are qualified with the dataset namespace.

Candidate features cover both subscriber level and aggregates:

- Subscriber level: daily, modal, home and last location, radius of gyration, event counts,
  subscriber degree, contact balance, nocturnal events, entropy, interevent intervals, call durations,
  topup amounts and handset stats.
- Aggregates: unique subscriber counts, total network objects, flows and OD matrices.

Queries go in `flowkit/<scale>/queries/` and the schema in `flowkit/<scale>/schema/`, following the root README.
