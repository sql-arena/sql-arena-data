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
| [FraudZen](https://gitlab.inria.fr/simbox-fraud-mitigation) (INRIA) | Simulator of synthetic CDRs with SIM-box fraud | Published set is ~119 MB | No | None | Open source (unverified) | Built for fraud detection research, not SQL benchmarking. |
| [TATP](https://tatpbenchmark.sourceforge.net/) | Telecom OLTP benchmark simulating a Home Location Register | Number of subscribers | No | 7 transactions, no analytical queries | Open (unverified) | Subscriber register only; contains no call records. |

Telecom Italia Big Data Challenge was integrated on 2026-10-08 and is listed in [DATASETS.md](./DATASETS.md).
Its source, download flow and validation are in [telecomitalia/README.md](./telecomitalia/README.md).

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

## Needle-in-a-Haystack

Datasets whose realistic queries are point lookups or very selective filters: one account, user, host, IP, hash or
address, or a substring (`LIKE '%...%'`) in long text. Researched 2026-10-26; ✓ marks a licence or size checked
at the source that day.

Security and threat hunting is where these queries are the main workload. Detection rules and hunts are filters on
single events, mostly with leading-wildcard `LIKE`. Advertising has the access pattern in production (per-user
deletion, click-fraud lookups by IP), but the public ad datasets are ML click-through sets with hashed features
(Criteo), Kaggle competition data that cannot be redistributed (Avazu, TalkingData), or have no licence (iPinYou).
ClickBench `hits` is the only real web analytics set, and 6 to 11 of its 43 queries are needle style.

| Dataset | What it is | Size | Queries? | Queries | Licence | Notes |
|---|---|---|---|---|---|---|
| [Splunk BOTS v1](https://github.com/splunk/botsv1) | Boss of the SOC capture-the-flag: real attack on a small company network in August 2016, with Windows event logs, Sysmon, firewall, Suricata and network stream logs | JSON export 12.1 GB gzip ✓, ~120 GB raw, one file per sourcetype; tens of millions of events (est.) | Partial | 32 CTF questions with known answers (about 25 usable without outside lookups), written as SPL in write-ups; [Sigma](https://github.com/SigmaHQ/sigma) rules rendered to SQL by [Zircolite](https://github.com/wagga40/Zircolite) (2,840 Sysmon rules, 92% leading-wildcard `LIKE` ✓); 81 Spark SQL queries in the [ThreatHunter-Playbook](https://github.com/OTRF/ThreatHunter-Playbook) | CC0 ✓; Sigma rules DRL 1.1; Playbook MIT ✓ | Best needle candidate. Fixed size, but can be scaled by replicating benign rows with shifted time and hosts, keeping attack rows unique. Sigma matching is case-insensitive, so rules need `ILIKE` or `lower()` outside SQLite. BOTS v2 and v3 are CC0 too, but only as pre-indexed Splunk buckets. |
| [Ethereum transactions](https://registry.opendata.aws/aws-public-blockchain/) (AWS Public Blockchain) | Every Ethereum (and Bitcoin) transaction, log and token transfer | `eth/transactions` 1.5 TB Parquet ✓, `eth/logs` 1.3 TB, `btc/transactions` 2.2 TB; grows daily | No | Would write ~20: transactions of an address, by hash, token transfers of a wallet, calldata prefix | Public ledger data; re-hosting looks safe but confirm with AWS Open Data | Flat Parquet partitioned by date. Extreme skew from one-transaction wallets to exchange wallets with tens of millions of rows. Bitcoin inputs and outputs are nested arrays. |
| [OpenSearch big5](https://github.com/opensearch-project/opensearch-benchmark-workloads/tree/main/big5) | Synthetic log documents with keyword fields and word-salad messages | 116M docs (6 GB bz2) or 1.16B docs (1.07 TB JSON) ✓ | Partial | About 8 to 10 term and token queries among ~45 operations, in Query DSL and PPL | Apache-2.0 ✓; Elastic's generator is Elastic License 2.0 | Re-host the published corpus, don't regenerate. Nested JSON with a fixed schema, about 25 columns flat. Low-entropy text. |
| [LANL Comprehensive Cyber Events](https://csr.lanl.gov/data/cyber1/) | 58 days of authentication, process, flow and DNS events from LANL's network | 1.65B events ✓, ~12 GB compressed | No | Would write them from the red-team file (~749 compromise events) as needles | CC0 ✓ | Flat CSV. Anonymised (`U748@DOM1`, `C17693`), so no text to search. |
| [IBM AML transactions](https://www.kaggle.com/datasets/ealtman2019/ibm-transactions-for-anti-money-laundering-aml) | Synthetic bank transfers with labelled laundering patterns | Six sets from 5M to 180M rows ✓ | No | Would write account statements and counterparties, with the pattern files as parameters | CDLA-Sharing 1.0 ✓ | Flat CSV. Generator lineage is AMLSim (Apache-2.0). |

Already listed elsewhere: ClickBench `hits` (Q19 `UserID` lookup, Q20 to Q23 `URL LIKE '%google%'`, Q40 and Q41 hash
equality), GH Archive (13 of ~50 ClickHouse queries filter one repo or user) and Wikipedia pageviews (one article over
time). LDBC SNB Interactive short reads (IS1 to IS7) are point lookups that come with the SNB datagen.

## Not Suitable

| Dataset | Reason |
|---|---|
| Amazon customer reviews | Research-only licence; cannot be re-hosted publicly. |
| [LDBC FinBench](https://ldbcouncil.org/benchmarks/finbench/) | Tops out at ~6 GB and the queries are graph queries, not SQL. |
| Spider 2.0 / BIRD | Text-to-SQL benchmarks; data is small or licensed through Snowflake and BigQuery marketplaces. |
| Loghub | Licence limits use to research and academic work. |
| CIC-IDS2017, UNSW-NB15 | Labelled flow features for ML classifiers; no redistribution licence, or no commercial use. |
| Criteo 1TB click logs | Features hashed to 32 bits, so needle queries would be arbitrary; CC BY-NC-SA. |
| Avazu, TalkingData AdTrack | Kaggle competition data; cannot be redistributed. |
| iPinYou RTB | Right columns for ad needles (user ID, IP, URL), but no licence anywhere. |
| Common Crawl URL index | Terms of use forbid redistribution, and the bucket needs credentials. |
| OTRF Security-Datasets, Splunk attack_data | Too small to be the haystack; MIT and Apache-2.0, so usable as extra needles mixed into one. |
| [Redset / Redbench](https://arxiv.org/abs/2511.13059) | Redshift workload traces, not data. Worth revisiting to build realistic query streams over datasets we already host. |

## Suggested Order

1. SSB and JCC-H: dbgen-style C generators that fit the approach of the existing `tpch` generator.
2. DSB: the same idea on top of TPC-DS.
3. LDBC SNB BI, then LSQB: the headline non-TPC addition. Its Spark datagen is a good first job for EC2 based generation.
4. SQLStorm StackOverflow data, for query variety.
5. FlowKit CDR: a home-grown, deterministic DuckDB generator for FlowKit's schema, with queries rendered by FlowKit (in progress).
6. Splunk BOTS v1: the needle-in-a-haystack workload, with Sigma rules and BOTS questions as queries (in progress).
