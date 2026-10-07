# Candidate Datasets

Public datasets and dataset generators that ship with example SQL queries and could be added to
`s3://sql-arena` next to TPC-H, TPC-DS, JOB, NYC Taxi and the Public BI Benchmark. Researched October 2026.

The licence column matters because we re-host the data in a public bucket. A licence marked ✓ was
checked against the source repository or data host on 2026-10-07; the rest are still unverified.
For generators the licence is the generator's; the generated data is ours to publish unless noted.

The "Queries?" column says whether a ready-made SQL query set exists: **Yes** (SQL we can extract),
**Partial** (examples only, or some queries are not plain SQL) or **No** (we would have to write them).

## Scalable Generators

These can produce TB sized data by increasing a scale factor.

| Dataset | What it is | Scaling | Queries? | Queries | Licence | Notes |
|---|---|---|---|---|---|---|
| [LDBC SNB BI](https://github.com/ldbc/ldbc_snb_bi) | Synthetic social network with correlated, skewed attributes and many-to-many joins | Spark [datagen](https://github.com/ldbc/ldbc_snb_datagen_spark), CSV or Parquet. SF10K is ~4.8 TB; SF30K has been generated on 20 AWS machines | Yes | ~20 BI read queries; SQL reference implementation for Umbra (Postgres dialect) | Apache-2.0 ✓ (bi and datagen repos) | Best non-TPC candidate. Deep, many-to-many joins stress the optimizer. Needs Spark. |
| [LSQB](https://github.com/ldbc/lsqb) | LDBC SNB graph with attributes removed | SF0.1 to SF1000 | Yes | 9 subgraph matching queries (multi-way joins in SQL) | Apache-2.0 ✓ | Tests join ordering. Comes almost free once the SNB datagen runs. |
| [SSB](https://github.com/eyalroz/ssb-dbgen) (Star Schema Benchmark) | Star schema rework of TPC-H | `ssb-dbgen -s N`; SF1000 has 6B `lineorder` rows | Yes | 13 queries in 4 flights | No licence file ✓ (eyalroz and electrum forks). The code is a fork of TPC-H dbgen, so the TPC EULA effectively applies | Same footing as the TPC-H data we already host. Cheapest to add. |
| [JCC-H](https://ir.cwi.nl/pub/27429) | Drop-in replacement for TPC-H dbgen with skew and join-crossing correlations | Same scale factors as TPC-H | Yes | 22 TPC-H queries with normal or skewed parameters | Unverified. Also a dbgen fork, so the TPC EULA likely applies | Same queries, but plans built on uniformity assumptions break. Very relevant for plan comparisons. |
| [TPC-H skew](https://www.microsoft.com/download/details.aspx?id=52430) (Microsoft) | TPC-H dbgen with Zipfian columns | TPC-H scale factors, Zipf factor `-z 0..4` | Yes | 22 TPC-H queries | Microsoft download licence (unverified) | Older and simpler alternative to JCC-H. |
| [DSB](https://github.com/microsoft/dsb) (Microsoft) | TPC-DS with skew and cross-table correlations | TPC-DS scale factors; tables must be generated in a fixed order. The sample index set in the README was tuned on SF100; the largest tested SF is not stated | Yes | 39 templates (16 aggregate + 23 multi-block, including the new 100, 101 and 102) plus 16 single-block SPJ variants, each in Postgres and SQL Server dialects ✓ | MIT ✓ | Data and query tools tested only on Windows Server 2019. |
| [Coffee-shop](https://github.com/JosueBogran/coffeeshopdatagenerator) | One sales fact table, two small dimensions, intentionally messy data | Number of orders; the "5B" scale has 7.2B fact rows | Yes | 17 join-heavy queries | MIT ✓, attribution requested | Used by ClickHouse, Databricks, Snowflake, Doris. Pre-generated data is in a public S3 bucket. |
| [TSBS](https://github.com/timescale/tsbs) | Time series (DevOps, CPU-only and IoT scenarios) | `--scale` (hosts) times the timestamp range | Yes | Generated per database; SQL for TimescaleDB, ClickHouse, QuestDB, CrateDB | MIT ✓ | Different workload: time bucketed aggregations and last-value queries. |
| [H2O db-benchmark](https://github.com/duckdblabs/db-benchmark) | Group-by and join over generated columns of small, medium and large cardinality | Row count, typically up to 1e9 rows (~50 GB) | Yes | Group-by and join tasks; SQL versions in the DuckDB and ClickHouse solutions | MPL-2.0 ✓ (original h2oai repo and the maintained duckdblabs fork) | Narrow, but widely cited. |
| [TPCx-BB / BigBench](https://arxiv.org/pdf/1512.08417) | Retail data with structured, semi-structured and unstructured parts | PDGF generator, 1 TB to petabytes | Partial | 30 queries; several use ML or UDFs rather than plain SQL | TPC EULA (unverified) | Heavy kit. Low priority. |
| [CH-benCHmark](https://db.in.tum.de/research/projects/CHbenCHmark/) | TPC-C plus 22 adapted TPC-H queries | Number of warehouses | Yes | 22 analytical queries plus TPC-C transactions | Apache-2.0 ✓ (BenchBase) | Loads into a database over JDBC rather than writing files, so it fits the bucket model poorly. |

## Fixed Real-World Datasets

Real data with known example queries, but no scale factor.

| Dataset | What it is | Size | Queries? | Queries | Licence | Notes |
|---|---|---|---|---|---|---|
| [SQLStorm](https://github.com/SQL-Storm/SQLStorm) | StackOverflow data with LLM-generated queries | 1 GB (DBA), 12 GB (Math), 222 GB (full) | Yes | ~18K queries validated on Postgres, Umbra and DuckDB | Code MIT ✓; the data is a Stack Exchange dump, CC BY-SA | Huge query variety. Excellent for plan comparisons. |
| [GitHub events (GH Archive)](https://clickhouse.com/docs/getting-started/example-datasets) | All public GitHub events | 3.1B rows for 2011-2020, still growing | Yes | Extensive ClickHouse analysis query set (ClickHouse dialect) | Public GitHub API data | Mostly single-table aggregations. |
| OnTime flights (US BTS) | US flight delays since 1987 | ~200M rows | Yes | ClickHouse numbered query set | US government, public domain | Classic, small. |
| Wikipedia pageviews | Hourly page view counts | Hundreds of billions of rows across all years | Partial | ClickHouse examples, mostly simple aggregations | CC0 | The only fixed set that is genuinely TB scale. |
| Environmental sensors (sensor.community) | Air quality and weather sensor readings | 20B+ rows | Partial | ClickHouse examples | ODbL | Single table. |
| OpenCelliD cell towers | Cell tower locations | ~40M rows | Partial | ClickHouse geo examples | CC BY-SA 4.0 | Useful as the tower dimension for a CDR dataset. |
| [STATS-CEB](https://github.com/Nathaniel-Han/End-to-End-CardEst-Benchmark) | Stats StackExchange dump with string columns removed | 8 tables, ~1.03M rows, 658 MB | Yes | 146 join queries built for cardinality estimation | Repo has no licence file ✓; the data is a Stack Exchange dump, CC BY-SA | Pairs naturally with JOB. |
| [ClickBench](https://github.com/ClickHouse/ClickBench) (hits) | Real web analytics, one wide table | 100M rows | Yes | 43 queries | CC BY-NC-SA 4.0 ✓ | Only grows by duplicating rows. Non-commercial and share-alike, so check before re-hosting. |
| [AMPLab Big Data Benchmark](https://amplab.cs.berkeley.edu/benchmark/) | Rankings and user visits | Tiny, 1node, 5nodes | Yes | 4 queries | Open | Unmaintained since ~2014. Skip. |

## Call Detail Records (CDR)

Real per-call CDRs are essentially never published because they are too sensitive.

| Dataset | What it is | Size | Queries? | Queries | Licence | Notes |
|---|---|---|---|---|---|---|
| [Telecom Italia Big Data Challenge](https://theodi.fbk.eu/openbigdata) | Milan and Trentino, Nov-Dec 2013: calls, SMS and internet activity aggregated per grid square in 10-minute slots, plus square-to-square and square-to-province interactions | ~717 GB of text across 19 Dataverse datasets; see below | No | None published; public code is ML traffic forecasting, not SQL | ODbL 1.0 ✓ (telecom, grids, social, electricity), CC BY 2.5 ✓ (weather), MIT ✓ (sample code) | Real data, but already aggregated: no individual calls or subscribers. Download needs a free Dataverse account. |
| [FraudZen](https://gitlab.inria.fr/simbox-fraud-mitigation) (INRIA) | Simulator of synthetic CDRs with SIM-box fraud | Published set is ~119 MB | No | None | Open source (unverified) | Built for fraud detection research, not SQL benchmarking. |
| [TATP](https://tatpbenchmark.sourceforge.net/) | Telecom OLTP benchmark simulating a Home Location Register | Number of subscribers | No | 7 transactions, no analytical queries | Open (unverified) | Subscriber register only; contains no call records. |

### Telecom Italia: getting the data

All files are on Harvard Dataverse under the
[`bigdatachallenge`](https://dataverse.harvard.edu/dataverse/bigdatachallenge) collection
(Dataverse 6.10). None of the files are restricted, but every telecom dataset is behind guestbook 96,
"Privacy risk assessment", which asks only for an email address (no custom questions).

| Dataverse dataset | DOI | Files | Size | Licence |
|---|---|---|---|---|
| Telecommunications - SMS, Call, Internet - MI | `10.7910/DVN/EGZHFV` | 62 daily `.txt` | 20.8 GB | ODbL 1.0 |
| Telecommunications - MI to MI | `10.7910/DVN/JZMTBJ` | 62 daily `.txt` | 370.0 GB | ODbL 1.0 |
| Telecommunications - MI to Provinces | `10.7910/DVN/F3RBMF` | 62 daily `.txt` | 16.1 GB | ODbL 1.0 |
| Telecommunications - SMS, Call, Internet - TN | `10.7910/DVN/QLCABU` | 62 daily `.txt` | 11.6 GB | ODbL 1.0 |
| Telecommunications - TN to TN | `10.7910/DVN/KCRS61` | 62 daily `.txt` | 291.8 GB | ODbL 1.0 |
| Telecommunications - TN to Provinces | `10.7910/DVN/MAW5AR` | 62 daily `.txt` | 6.3 GB | ODbL 1.0 |
| Milano Grid / Trentino Grid | `10.7910/DVN/QJWLFU`, `10.7910/DVN/FZRVSX` | 1 GeoJSON each | 3 MB, 2 MB | ODbL 1.0 |
| Administrative Regions | `10.7910/DVN/KNMIVZ` | 2 JSON | 2 MB | ODbL 1.0 |
| SET, Electricity (Trentino) | `10.7910/DVN/AMKZXM` | 3 CSV | 58 MB | ODbL 1.0 |
| Social Pulse - Milano / Trentino | `10.7910/DVN/9IZALB`, `10.7910/DVN/5H0NUI` | 1 GeoJSON each | 96 MB, 9 MB | ODbL 1.0 |
| MilanoToday / TrentoToday (news events) | `10.7910/DVN/QWOE1R`, `10.7910/DVN/NYQ23N` | 1 GeoJSON each | <1 MB | ODbL 1.0 |
| Milano Weather Station Data, Meteotrentino Weather Station Data | `10.7910/DVN/9Z6CKW`, `10.7910/DVN/UPODNL` | 34 CSV, 1 JSON | 1 MB, 15 MB | CC BY 2.5 |
| Precipitation - Milano / Trentino | `10.7910/DVN/S2UGMD`, `10.7910/DVN/0RZVTA` | 1 CSV, 2 CSV | 1 MB, 74 MB | CC BY 2.5 |
| Source code | `10.7910/DVN/UTLAHU` | 3 `.py` | <1 MB | MIT |

File layout of the telecom files, according to the
[Scientific Data paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC4622222/) and public loader code.
The `sms-call-internet` layout and the download flow below were confirmed on 2026-10-07 by
downloading the first 1 KB of the first MI file. Setup and download steps are in
[telecomitalia/README.md](./telecomitalia/README.md).

- Tab separated, no header. Time is the start of the 10-minute slot in epoch milliseconds (UTC). Activity values are
  scaled by an undisclosed constant, so they are relative, not counts. Rows with no activity are
  omitted and missing measures are empty.
- `sms-call-internet-*`: `square_id, time_interval, country_code, sms_in, sms_out, call_in, call_out, internet`.
- `MItoMI` / `TNtoTN`: `time_interval, square_id_1, square_id_2, strength`.
- `*-to-provinces`: `square_id, province, time_interval, cell_to_province, province_to_cell`.
- Milan grid: 10,000 squares (100 x 100, ~235 m). Trentino grid: 6,575 squares.

Row counts are not published. From file size, MI to MI is roughly 10B rows and SMS-Call-Internet MI
is roughly 300M rows. Confirm both after the first download.

**Can it be scripted? Yes, but it needs a free Harvard Dataverse account.** Anonymous `GET
/api/access/datafile/{id}` returns `400 "You may not download this file without the required
Guestbook response for guestbookID 96"`. The Dataverse API lets you submit the guestbook response
programmatically, but only with an API token:

1. List files: `GET /api/datasets/:persistentId/?persistentId=doi:10.7910/DVN/<DOI>` returns each
   file's id, name and size. No auth needed.
2. Per file, `POST /api/access/datafile/{id}` with header `X-Dataverse-key: $TOKEN` and body
   `{"guestbookResponse": {"email": "..."}}`. This returns a signed URL; `GET` it to stream the file.
   `POST /api/access/datafiles` with `{"fileIds": [...], "guestbookResponse": {...}}` does several
   files at once as a zip, but Harvard caps zip size, so per-file is safer for the 6 GB files.
3. Single `Range` requests are supported, so large files can resume after a failed download.

The account itself can't sensibly be automated. Dataverse can create accounts over the API
(`/api/builtin-users`), but only with a server-side `:BuiltinUsersKey`, and Harvard returns 403 on that endpoint.
The other routes are the sign-up web form or login via ORCID, GitHub, Google or Microsoft, which
would mean scripting a browser through someone's identity. So the account and the first token are
a one-time manual step, a couple of minutes in the web UI (account name → API Token → Create Token).
After that, the token can be maintained by script: `GET /api/users/token` returns its expiry and
`POST /api/users/token/recreate?returnExpiration=true` swaps it for a new one, so a job can renew
it before it lapses and write it back to the secret store.

A generator would loop over the 6 telecom DOIs (plus the grids), download a day at a time and
convert it to parquet sorted by `time_interval`. It needs the token and the email as secrets.
That is ~717 GB down from Harvard, so it is better run on EC2 than on a laptop. ODbL allows re-hosting with
attribution, and anything derived from the data must stay under ODbL. There is no query set, so
the queries would have to be written by hand: hourly and daily rollups per square, top squares,
country-code mix (roaming), origin-destination flows from MI to MI, and joins to the grid and
weather.

### CDR generators

Searched GitHub and the literature on 2026-10-07 for synthetic CDR generators that can build very
large tables. None is deterministic, parallel, scalable to TB size and permissively licensed all at once,
and none ships SQL queries.

| Generator | Language / engine | Scaling | Deterministic | Licence | Verdict |
|---|---|---|---|---|---|
| [whetherharder/cdr-generator](https://github.com/whetherharder/cdr-generator) | Python, multiprocess (subscriber sharding) | Subscribers x days. The README targets 10M+ subscribers and billions of rows, but the current baseline is ~1,500 records/s per core | Yes (seeded) | None ✓ (cannot reuse) | Most realistic model: voice/SMS/data, 26-field 3GPP-style records, Zipf contact book, hourly and weekday weights, mobility and handover, anomaly injection. Too slow and unlicensed, but a good model to copy. Active (2026). |
| [mrafalo/fastcdrgen](https://github.com/mrafalo/fastcdrgen) | Rust, single process | Customers x relations x calls per relation; batched CSV | No (`thread_rng`) | MIT text in the README, no LICENSE file | Markov-chain behaviour with fraud, SIM-box, multi-SIM and churn profiles, plus BTS ids. Not reproducible, and it writes one file. |
| [RealImpactAnalytics/cdr-generator](https://github.com/marivipelaez/cdr-generator) | Scala on Spark (GraphX social graph) | Cells, users and social graph, one simulated day per pass | Not stated | Original repo deleted; the surviving copy has no licence | Right architecture for scale (Spark, graph-driven), but abandoned since 2017. |
| [qvantel/orcd-generator](https://github.com/qvantel/orcd-generator) | Scala on Spark, writes to Cassandra | Configurable CDR count and history | No | MIT ✓ | Trend-driven (voice, SMS, MMS, data per country) for a roaming dashboard. Writes to Cassandra, not files. Unmaintained since 2017. |
| [mayconbordin/cdr-gen](https://github.com/mayconbordin/cdr-gen) | Java, in memory | Accounts x calls per account | No | MIT ✓ | Billing-oriented (call types, off-peak, cost per minute). Builds the whole population in memory, so it won't reach TB size. |
| [mplpl/MobileNetworkSimulator](https://github.com/mplpl/MobileNetworkSimulator) | Python, single process | Subscribers x days | No | MIT ✓ | Small and simple: MO/MT legs, BTS location, SIM-box fraud. Good reference for a two-table model (`cdr`, `imsi`). |
| [CARD-AI/CDR-Generator](https://github.com/CARD-AI/CDR-Generator) | Python, single process | Customers, one month | No | MIT ✓ | Calibrated on real Lithuanian telco data (IVUS 2021 paper); friend and acquaintance graph, event scenarios. Small scale. |
| [NetEventSimulator](https://github.com/bogdanoancea/simulator) (ESSnet Big Data) | C++ micro-simulation | Persons moving on a map, with antennas | Seeded | EUPL-1.2 ✓ | Network signalling events with ground-truth positions, for official statistics. Not call records, and not built for volume. |
| [dbldatagen](https://github.com/databrickslabs/dbldatagen) (Databricks Labs) | PySpark | Billions of rows in minutes | Yes | Databricks License ✓: use only with Databricks services | Generic generator, not CDR-specific. The licence rules it out for our DuckDB pipeline. |
| [FraudZen](https://gitlab.inria.fr/simbox-fraud-mitigation) (INRIA) | Simulator | ~119 MB published set | | Unverified | Fraud research; see the table above. |

Conclusion: nothing can be adopted as is, so the home-grown generator below remains the plan. Ideas
worth borrowing: whetherharder's record layout, contact book and temporal weights; the
fraud/SIM-box/churn profiles from fastcdrgen and MobileNetworkSimulator; and Telecom Italia's real
per-square activity curves for calibration.

### CDR query sets

Searched 2026-10-07 for published CDR SQL we could generate data to match. There is no CDR
benchmark query set, but one real-world source stands out:

**[Flowminder FlowKit](https://github.com/Flowminder/FlowKit)** (MPL-2.0 ✓, active in 2026). FlowKit is
the toolkit Flowminder uses to analyse real operator CDRs for humanitarian work. It has three parts that fit together:

- A fixed CDR schema in Postgres ([`flowdb/bin/build/0020_schema_events.sql`](https://github.com/Flowminder/FlowKit/blob/master/flowdb/bin/build/0020_schema_events.sql)):
  `events.calls`, `events.sms`, `events.mds` (mobile data sessions), `events.topups` and `events.forwards`,
  each holding `msisdn`, `msisdn_counterpart`, `datetime`, `duration`, `location_id`, `imsi`, `imei`, `tac` and
  operator/country codes. Alongside are `infrastructure.cells`, `sites` and `tacs`, plus admin-boundary geography.
- A synthetic data generator written as SQL run from Python
  ([`generate_synthetic_data_sql.py`](https://github.com/Flowminder/FlowKit/blob/master/flowdb/testdata/bin/generate_synthetic_data_sql.py)).
  It scales by `--n-subscribers`, `--n-cells`, `--n-sites`, `--n-tacs`, `--n-calls/--n-sms/--n-mds` per day and
  `--n-days`. Subscribers have home regions, out-of-area and relocation probabilities, an interaction graph
  (`--interactions-multiplier`) and an optional "disaster" displacement. It runs inside Postgres/PostGIS and uses
  `random()`, so it is not deterministic as written.
- About 100 query classes in `flowmachine/features/` that each produce one SQL statement. Subscriber-level ones
  include daily, modal, home and last location, radius of gyration, event counts, subscriber degree, contact balance,
  nocturnal events, entropy, interevent intervals, call durations, topup amounts and handset stats. Aggregates include
  unique subscriber counts, total network objects, flows and OD matrices, trips and meaningful locations. Only 16
  rendered SQL snapshots are checked in (`*_sql.approved.txt`, mostly `daily_location` and `event_count`). The rest
  are rendered by building each query object with fixed parameters and calling `get_query()`, which needs a running
  FlowDB (`flowminder/flowdb-testdata` Docker image). That is a one-time extraction script, the same as how we take
  queries from other upstream repositories.

Caveats: the SQL is Postgres dialect (`DISTINCT ON`, `::` casts) and the location queries join cells to
regions with PostGIS `st_within`. To keep to plain SQL and Iceberg types, we would precompute a
`cell_region` mapping table and rewrite that join. Some features query internal cache tables and would need trimming.

Other sources checked and rejected:

- Databricks `lakehouse-industry-data-models` telecommunication model: Unity Catalog metric-view YAML, not
  queries, and no standard open licence.
- ClickHouse_Demos `telco_marketing`: a workshop demo with its own data generator, but the repo has no licence.
- Blog and portfolio projects (Snowflake fraud demo, hobby "Telecom CDR analytics" repos): a handful of ad-hoc
  queries each, no licence, not worth matching.

Recommendation (agreed with the user 2026-10-07): make the home-grown generator produce FlowKit's schema,
and take the query set from SQL rendered by FlowKit's `flowmachine`, after the PostGIS rewrite. That gives a public, real-world, MPL-licensed
query set. The generator can be rewritten in DuckDB SQL from FlowKit's synthetic generator, with
hash-based randomness so it is deterministic, and made to scale by subscribers x days.

### Home-grown CDR generator

Status: in progress as the `flowkit` dataset; see [flowkit/README.md](./flowkit/README.md). It follows
FlowKit's schema and queries, as described above. The original proposal follows.

Proposal: write our own CDR generator in DuckDB SQL, in the style of dbgen. Deterministic, scaled by
subscribers times days, with a heavy-tailed calling graph and OpenCelliD towers as the location
dimension. The query set would cover billing rollups, top talkers, roaming, call sessions, churn
windows and "who called whom" chains. The Telecom Italia activity curves (per 10 minutes, per square)
could be used to calibrate the generator's daily and weekly load shape.

## Not Suitable

| Dataset | Reason |
|---|---|
| Amazon customer reviews | Research-only licence; cannot be re-hosted publicly. |
| [LDBC FinBench](https://ldbcouncil.org/benchmarks/finbench/) | Tops out at ~6 GB and the queries are graph queries, not SQL. |
| Spider 2.0 / BIRD | Text-to-SQL benchmarks; data is small or licensed through Snowflake and BigQuery marketplaces. |
| [Redset / Redbench](https://arxiv.org/abs/2511.13059) | Redshift workload traces, not data. Worth revisiting to build realistic query streams over datasets we already host. |

## Suggested Order

1. SSB and JCC-H: dbgen-style C generators that fit the approach of the existing `tpch` generator.
2. DSB: the same idea on top of TPC-DS.
3. LDBC SNB BI, then LSQB: the headline non-TPC addition. Its Spark datagen is a good first job for EC2 based generation.
4. SQLStorm StackOverflow data, for query variety.
5. Telecom Italia: real, ODbL, ~717 GB, scriptable with a Dataverse token. Generator and hand-written queries done; the full EC2 run is pending.
6. FlowKit CDR: a home-grown, deterministic DuckDB generator for FlowKit's schema, with queries rendered by FlowKit (in progress).
