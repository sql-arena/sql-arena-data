#!/usr/bin/env bash
set -euo pipefail

# label used to identify containers started by this script
LABEL="sql-arena-managed=true"

# Usage check
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 \"<SQL Server|PostgreSQL|ClickHouse|Trino>\""
    exit 1
fi

INPUT_DB="$1"
DB_LOWER=$(echo "$INPUT_DB" | tr '[:upper:]' '[:lower:]')

case "$DB_LOWER" in
    "sql server")
        DB_TYPE="mssql"
        IMAGE_TAG="sql-arena-mssql"
        CONTAINER_NAME="sql-arena-mssql"
        PORT_MAPPING="1433:1433"
        ;;
    "postgresql")
        DB_TYPE="postgresql"
        IMAGE_TAG="sql-arena-postgresql"
        CONTAINER_NAME="sql-arena-postgresql"
        PORT_MAPPING="5432:5432"
        ;;
    "clickhouse")
        DB_TYPE="clickhouse"
        IMAGE_TAG="sql-arena-clickhouse"
        CONTAINER_NAME="sql-arena-clickhouse"
        PORT_MAPPING="-p 8123:8123 -p 9000:9000"
        ;;
    "trino")
        DB_TYPE="trino"
        IMAGE_TAG="sql-arena-trino"
        CONTAINER_NAME="sql-arena-trino"
        PORT_MAPPING="8080:8080"
        ;;
    *)
        echo "Error: Unknown database type '$INPUT_DB'"
        echo "Supported types: \"SQL Server\", \"PostgreSQL\", \"ClickHouse\", \"Trino\""
        exit 1
        ;;
esac

# Check if any sql-arena-managed container is already running
RUNNING_CONTAINERS=$(docker ps --filter "label=${LABEL}" --format '{{.Names}}')
if [[ -n "${RUNNING_CONTAINERS}" ]]; then
    echo "Warning: The following database container(s) are already running:"
    echo "${RUNNING_CONTAINERS}"
    echo "Starting another one may cause port conflicts."
fi

# Build the image
echo "Building Docker image for ${INPUT_DB}..."
docker build -t "${IMAGE_TAG}" "docker/${DB_TYPE}/"

# Start the container
echo "Starting ${INPUT_DB} container..."
if [[ "$DB_TYPE" == "clickhouse" ]]; then
    # ClickHouse needs multiple ports, handled by PORT_MAPPING variable
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --label "${LABEL}" \
        ${PORT_MAPPING} \
        "${IMAGE_TAG}"
else
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --label "${LABEL}" \
        -p "${PORT_MAPPING}" \
        "${IMAGE_TAG}"
fi

echo "${INPUT_DB} started successfully."
