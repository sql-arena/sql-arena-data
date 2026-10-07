# FlowKit CDR

Synthetic mobile operator call detail records (CDR) in the schema of
[Flowminder FlowKit](https://github.com/Flowminder/FlowKit), with a query set rendered by FlowKit's
`flowmachine`. Flowminder uses FlowKit to analyse real operator CDRs for humanitarian work. That gives
the dataset a real-world query workload over data we can generate at any scale.

Status: the generator is in `flowkit/flowkit.py`; the query set is not rendered yet. Research notes are in
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

## Tables

Namespace `flowkit_sf<N>`. FlowKit's schemas `events`, `infrastructure` and `geography` are folded into it, and table and column names are kept:

| Table | Columns | Notes |
|---|---|---|
| `calls` | `id`, `outgoing`, `datetime TIMESTAMPTZ`, `duration DOUBLE`, `network`, `msisdn`, `msisdn_counterpart`, `location_id`, `imsi`, `imei`, `tac BIGINT`, `operator_code INT`, `country_code INT` | Two rows per call, outgoing and incoming, with the same `id` and `datetime` |
| `sms` | as `calls`, without `duration` | Two rows per SMS |
| `mds` | `id`, `datetime`, `duration`, `volume_total`, `volume_upload`, `volume_download DOUBLE`, `msisdn`, `location_id`, `imsi`, `imei`, `tac`, `operator_code`, `country_code` | Mobile data sessions |
| `topups` | `id`, `datetime`, `type`, `recharge_amount`, `airtime_fee`, `tax_and_fee`, `pre_event_balance`, `post_event_balance DECIMAL(12,2)`, `msisdn`, `location_id`, `imsi`, `imei`, `tac`, `operator_code`, `country_code` | Not in FlowKit's generator; added so topup features have data |
| `cells`, `sites` | `cell_id`/`site_id BIGINT`, `id`, `version`, (`site_id`), `date_of_first_service`, `date_of_last_service DATE`, `geom_point` (WKT), `longitude`, `latitude` | The columns FlowKit's generator fills |
| `tacs` | `id BIGINT`, `brand`, `model`, `hnd_type` | 4,000 handset models |
| `admin1`, `admin2`, `admin3` | `gid`, `admin<N>pcod`, `admin<N>name`, `parent_pcod`, `geom` (WKT polygon) | FlowKit's `geography.admin<N>` views |
| `cell_region` | `location_id`, `admin3pcod`, `admin2pcod`, `admin1pcod` | Replaces PostGIS `st_within` from cells to admin regions |

`location_id` in the events is a cell's `id`. `operator_code`, `country_code` and `network` are NULL, as in FlowKit's test data. Times are UTC, from 2016-01-01.

## Generation

`flowkit/sql/` is a DuckDB SQL port of FlowKit's
[`generate_synthetic_data_sql.py`](https://github.com/Flowminder/FlowKit/blob/24d88247d57987fe33f6b8915540d7bf09b58033/flowdb/testdata/bin/generate_synthetic_data_sql.py)
and keeps its model:

- **Sites** are placed by population, and each gets one or more **cells** at its location. **Subscribers** get a random handset.
- Each subscriber has a **home cell**, chosen uniformly over cells so homes follow population, and moves to a new one with a 1% chance each day.
- Calls and SMS pick one of 5 x subscribers random **caller/callee pairs**, which gives everyone a set of contacts.
- Each event happens at a cell within 3 km of the subscriber's home that day, or at any cell with 5% chance.
- Call duration is uniform up to 2,600 s. MDS duration is uniform up to 260 s, with volumes up to 100,000.

Changes from upstream:

- **Deterministic.** Every random draw is `md5` of a salt and the row's key, so every run and scale factor is reproducible.
- **Scale.** SF N is N x 100,000 subscribers, with one cell per 100 subscribers (at least 1,000) and three cells per site. Per subscriber and day there are 3 calls, 4 SMS, 5 data sessions and a 10% chance of a topup; upstream sets fixed totals per day. `--days` (default 31) sets the length.
- **Geography.** A synthetic country replaces GADM, whose boundaries cannot be redistributed: 8 provinces, 72 districts and 648 municipalities on a fixed grid. Pcodes follow GADM's style (`SYN.3.4.5_1`). Municipalities have a heavy-tailed population weight, so a few cities hold most sites and subscribers, while many rural municipalities have no cell.
- **Hours.** Events follow an hourly profile (quiet nights, busy evenings) instead of being uniform over the day.
- **Topups** are added. The optional "disaster" displacement is not ported.

## Bucket Layout and Generating

```text
flowkit/sf<N>/<table>/<table>[_NNNN].{parquet,csv.zip}
flowkit/sf<N>/queries/, flowkit/sf<N>/schema/
```

```bash
uv run generate.py flowkit --sf 1                     # 100,000 subscribers, 31 days, ~59M event rows, ~9 GB parquet
uv run generate.py flowkit --sf 1 --days 7 --no-upload
```

Event tables are generated in chunks of consecutive days (`--days-per-chunk`, default about one 500 MB file each), sorted by `datetime`, and resume per chunk through `_manifest.json`. The static tables are single files. Event volume grows linearly in subscribers x days: SF1 for 7 days takes under 2 minutes on a laptop.

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
