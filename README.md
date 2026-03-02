# SQL Arena Data Gen

Tool to generate the data used by SQL Arena and provide Docker-based database infrastructure for benchmarking.

## Data Generation

Usage:

```bash
./gen.sh
```

Generates SF1 (children=1, step=0) and SF1000 (children=100, step 0-100) datasets for both TPC-H and TPC-DS, along with the JOB dataset.

## Docker Infrastructure

The `docker/` directory contains Dockerfiles and configurations for starting various databases to benchmark against.

You can use the provided scripts to manage the database containers:

```bash
# Start a database (case-insensitive: "SQL Server", "PostgreSQL", "ClickHouse", or "Trino")
./start.sh "PostgreSQL"

# Stop all containers started by start.sh
./stop.sh
```

Supported databases:
- **PostgreSQL**: `docker/postgresql/Dockerfile` (Port 5432)
- **SQL Server**: `docker/mssql/Dockerfile` (Port 1433, Developer Edition)
- **ClickHouse**: `docker/clickhouse/Dockerfile` (Port 8123 HTTP, Port 9000 Native)
- **Trino**: `docker/trino/Dockerfile` (Port 8080)

## Datasets

Currently available datasets

## Format

Datasets are available in two formats:

- Zipped CSV
  - `|` Column separator
  - `\n` Row Separator (LF / 0x0A)
  - Quoted string (where needed)
  - First line is the header 
- Parquet

## Public Buckets
The data is publicly available in:

```text
gs://sql-arena-data
s3://sql-arena-data
```


