#!/usr/bin/env bash
set -euo pipefail

# label used to identify containers started by start.sh
LABEL="sql-arena-managed=true"

# Find all running containers with the label
CONTAINERS=$(docker ps -q --filter "label=${LABEL}")

if [[ -z "${CONTAINERS}" ]]; then
    echo "No running SQL Arena managed containers found."
    exit 0
fi

# Stop and remove the containers
echo "Stopping and removing SQL Arena managed containers..."
docker stop ${CONTAINERS} > /dev/null
docker rm ${CONTAINERS} > /dev/null

echo "Stopped and removed all containers started by start.sh."
