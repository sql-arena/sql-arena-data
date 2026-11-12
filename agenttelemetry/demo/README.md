# Agent Telemetry on S3 Tables

Two containers that generate [Agent Telemetry](../README.md) into Amazon S3 Tables: a coordinator, which also serves a small web app to watch the generation and query the tables with DuckDB, and workers that generate and insert the data.

## What It Does

- The coordinator (`coordinator.Dockerfile`, the SvelteKit app in `web/`) plans a run and hands out its chunks.
  - Starting scale factor N runs `agenttelemetry/s3tables.py plan`. It creates namespace `agenttelemetry_sf<N>` in table bucket `sql-arena-agenttelemetry` and its tables, loads `tenants` and `model_prices`, and lists the chunks: slices of up to 2,500 sessions of one day, about 45,000 spans, which a process generates in under 2 GB.
  - It hands out one chunk at a time to whichever worker process asks, so workers can join or leave during a run, and a chunk whose worker went quiet for 30 minutes goes to another.
  - Workers tell it which files they wrote for a chunk. Every 2 seconds, each table that has such chunks and no commit under way gets one commit of up to 400 chunks, which `agenttelemetry/iceberg_append.py` makes: it writes a manifest of the files and a manifest list, and commits the snapshot to the S3 Tables catalog, without reading the data. One commit per table at a time means commits never race each other; one that loses to a compaction is made again on top of it, and one that fails is tried again with the next batch.
  - Written chunks, commits and failures go into a ledger in `STATUS_DIR`, so a restarted coordinator commits what was written and hands out only what is missing.
  - Workers get no new chunk while 400 written chunks wait for a commit.
- A worker (`worker.Dockerfile`) runs `agenttelemetry/s3tables.py work`: one process per CPU, each with one DuckDB thread and 2 GB of memory.
  - A process generates its chunk and writes `spans`, `traces` and `scores` of it as parquet files into each table's storage, one file per day partition, with the Iceberg field ids. A file is part of a table only once committed; S3 Tables removes files that never are.
  - A chunk that fails goes back to the queue, at most 3 times.
- The web app has four pages:
  - Generation: each run's progress, chunks being generated and staged, time to generate and write a chunk, commits per table with their size and time, failures, the plan step's log, the workers, and a form to start a scale factor.
  - Tables: data files and records of each table, and the status of the S3 Tables maintenance jobs.
  - Query: any query of `agenttelemetry/queries`, editable, run by DuckDB on the S3 Tables catalog.
  - Columns: approximate distinct values of each column, cached in `STATUS_DIR`.

## Table Layout

- Tables are Iceberg v3. In `spans`, `attributes`, `input_text` and `output_text` are `VARIANT`, as in the parquet files of the dataset.
- `spans` and `traces` are partitioned by day of `start_time`, `scores` by day of `created_at`.
- Their sort order is `trace_id, session_id`, and S3 Tables compaction uses the `z-order` strategy with 512 MB target files, so within a day the files cluster on both ids.
  Compaction combines the files of the commits.
- `tenants` and `model_prices` are unpartitioned, with the default compaction at 512 MB.
- The plan step creates the tables through the S3 Tables API, as DuckDB's `CREATE TABLE` sends metadata that S3 Tables rejects for `VARIANT` columns; DuckDB inserts into them.
  A namespace whose tables have another schema has to have its tables deleted first.

## Needles

Needles are computed, not listed: the macros in `agenttelemetry/sql/needles.sql` give the needle of a day `d` (0 is 2025-01-01) and a slot.

| Macro                   | Value                                                                           | Slots            | Query |
| ----------------------- | ------------------------------------------------------------------------------- | ---------------- | ----- |
| `needle_trace(d, n, 0)` | The first run of session n of day d                                             | 0 to 40 x SF - 1 | Q01   |
| `needle_session(d, n)`  | Session n of day d                                                              | 0 to 40 x SF - 1 | Q02   |
| `needle_code(d, k)`     | `ERR_` and 12 hex, in one tool result of day d and the model call that reads it | 0 to 3           | Q11   |
| `needle_place(d)`       | A place name with non-ASCII letters, in one support task of day d               | 1                | Q13   |

- Sessions 0 to 39 of every day exist at every scale factor and are the same runs, so a trace or session needle below 40 returns the same rows at every scale factor.
- The Query page puts the needle of the chosen day and slot into the query, with the time window the query uses.

## Environment

| Variable           | Meaning                                                                                             |
| ------------------ | --------------------------------------------------------------------------------------------------- |
| `TABLE_BUCKET_ARN` | The table bucket                                                                                    |
| `REPO_DIR`         | The repo inside the image, `/app/repo`                                                              |
| `STATUS_DIR`       | Plans, ledgers and plan logs of runs, and the cached distinct counts of the Columns page, `/data`   |
| `GENERATE_SF`      | A scale factor to generate when the server starts; unset to only serve                              |
| `HOST`, `PORT`     | Where the server listens, `127.0.0.1:8080`                                                          |
| `ORIGIN`           | The URL the browser uses, `http://localhost:8080`; form posts from any other origin are rejected    |

Of the worker:

| Variable          | Meaning                                                                       |
| ----------------- | ----------------------------------------------------------------------------- |
| `COORDINATOR_URL` | The coordinator, `http://127.0.0.1:8080`                                      |
| `WORKER_ARGS`     | Further options of `work`, such as `--processes 4`; none by default           |

The coordinator resumes, when it starts, every run in `STATUS_DIR/generation/sf<N>` that is not finished.
To generate a scale factor afresh, delete its tables and its directory there.

AWS credentials come from the default chain; on EC2, the instance role.
The role needs `s3tables:*` on the table bucket and its tables.

## Build and Run

Build from the repo root, for the machine that runs it (Graviton is `linux/arm64`):

```sh
docker build -f agenttelemetry/demo/coordinator.Dockerfile -t agenttelemetry-coordinator .
docker build -f agenttelemetry/demo/worker.Dockerfile -t agenttelemetry-worker .
docker run -d --network host -v /opt/demo/data:/data \
  -e TABLE_BUCKET_ARN=arn:aws:s3tables:<region>:<account>:bucket/sql-arena-agenttelemetry \
  -e AWS_REGION=<region> -e GENERATE_SF=10 agenttelemetry-coordinator
docker run -d --network host -e AWS_REGION=<region> agenttelemetry-worker
```

- `--network host` lets the containers reach the instance metadata service for the role's credentials, and the worker reach the coordinator.
- A machine needs 2 GB of memory per CPU for the worker, plus room for the coordinator: an m- or r-family instance, not c-family.
- Workers write to the tables' storage with the machine's credentials, so they can run on other machines too, given a private network path to the coordinator, which has no authentication; this setup makes none.
- The server listens on localhost only. Reach it through a Session Manager port forward:

```sh
aws ssm start-session --target <instance-id> --document-name AWS-StartPortForwardingSession \
  --parameters portNumber=8080,localPortNumber=8080
```

To forward to another local port, run the container with `-e ORIGIN=http://localhost:<port>`.

## Validate

`validate` compares the loaded data with the claims of the Agent Telemetry README, and fails if any is outside them:

```sh
docker exec <container> uv run --no-sync python -m agenttelemetry.s3tables validate --sf 10
```

## Develop

```sh
cd agenttelemetry/demo/web
npm install
npm run check && npm run lint && npm test
TABLE_BUCKET_ARN=... REPO_DIR=../../.. STATUS_DIR=/tmp/demo npm run dev
```
