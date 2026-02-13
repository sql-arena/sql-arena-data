#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./gen_tpch_tpcds.sh [sf] 
#
# Example:
#   ./gen_tpc.sh 1 benchmarks.duckdb gen_tpch_tpcds.sql

SF="${1:-1}"

DBFILE="benchmarks.duckdb"
SQLFILE="duckgenerate.sql"

JOB_DIR="job"
JOB_TGZ="${JOB_DIR}/imdb.tgz"
JOB_URL="https://bonsai.cedardb.com/job/imdb.tgz"


if [[ -f "${DBFILE}" ]]; then
  echo "Removing existing database: ${DBFILE}"
  rm -f -- "${DBFILE}"
fi

# Preconditions: create directories (DuckDB SQL cannot mkdir)
mkdir -p "${JOB_DIR}"

if [[ ! -f "$JOB_TGZ" ]]; then
  echo "Downloading JOB dataset: $JOB_URL"
  (cd "$JOB_DIR" && curl -fL -O "$JOB_URL")
fi

if [[ ! -f "${JOB_DIR}/title.csv" ]]; then
  echo "Extracting $JOB_TGZ"
  (cd "$JOB_DIR" && tar -zxvf "$(basename "$JOB_TGZ")" >/dev/null)
fi

echo "Renaming CSV of JOB to TXT in prep for reformatting"
shopt -s nullglob
for f in "${JOB_DIR}"/*.csv; do
  txt="${f%.csv}.txt"
  if [[ ! -f "$txt" ]]; then
    mv "$f" "$txt"
  fi
done

echo "Constructing JOB schema"
{
  echo "CREATE SCHEMA IF NOT EXISTS job;"
  echo "USE job;"
  cat "job/schematext.sql"
} | duckdb -bail -batch "$DBFILE" >/dev/null

echo "Loading JOB schema from downloaded files"

cat ducktransformjob.sql | duckdb -bail -batch "$DBFILE" >/dev/null


echo "Generating TPC Datasets"

TPCH_BASE="tpc-h/sf${SF}"
TPCDS_BASE="tpc-ds/sf${SF}"

mkdir -p "${TPCH_BASE}" 
mkdir -p "${TPCDS_BASE}" 

sed "s/%%SF%%/${SF}/g" "$SQLFILE" | duckdb -bail -batch "$DBFILE" >/dev/null

# Zip each CSV into its own .zip (next to the file)
zip_each_csv_dir () {
  local dir="$1"
  shopt -s nullglob

  for csv in "${dir}"/*.csv; do
    local base
    base="$(basename "$csv")"
    echo "  ${dir}/${base}"
    local zipname="${base}.zip"

    (
      cd "$dir"
      rm -f -- "$zipname"
      zip -q "$zipname" "$base"
    )
  done
}

echo "Zipping TPC-H CSV"
zip_each_csv_dir "${JOB_DIR}"
echo "Zipping TPC-H CSV"
zip_each_csv_dir "${TPCH_BASE}"
echo "Zipping TPC-DS CSV"
zip_each_csv_dir "${TPCDS_BASE}"

echo "Done."
