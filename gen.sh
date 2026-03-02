#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./gen.sh
#
# Generates SF1 (children=1, step=0) and SF1000 (children=100, step 0-100)
# for both TPC-H and TPC-DS datasets, along with the JOB dataset.

DBFILE="benchmarks.duckdb"
SQLFILE_BASE="duckgenerate_base.sql"
SQLFILE_STEP="duckgenerate_step.sql"

JOB_DIR="job"
JOB_TGZ="${JOB_DIR}/imdb.tgz"
JOB_URL="https://bonsai.cedardb.com/job/imdb.tgz"

# Function to generate base TPC tables (only once per SF)
generate_tpc_base () {
  local sf="$1"
  local delete_after="${2:-true}"

  echo "Generating TPC Base Tables for SF${sf}"

  local tpch_dir="tpch/sf${sf}"
  local tpcds_dir="tpcds/sf${sf}"

  mkdir -p "${tpch_dir}"
  mkdir -p "${tpcds_dir}"

  sed "s/%%SF%%/${sf}/g" "$SQLFILE_BASE" | duckdb -bail -batch >/dev/null

  # Upload (and delete if requested) the base files to preserve disk space
  upload_and_delete_files "${tpch_dir}" "tpch/sf${sf}" "" "" "${delete_after}"
  upload_and_delete_files "${tpcds_dir}" "tpcds/sf${sf}" "" "" "${delete_after}"
}

# Function to generate step-based TPC tables
generate_tpc_step () {
  local sf="$1"
  local children_num="$2"
  local step_num="$3"
  local delete_after="${4:-true}"
  local children=$(printf "%04d" "$children_num")
  local step=$(printf "%04d" "$step_num")

  echo "Generating TPC Step Tables for SF${sf} (Children: ${children}, Step: ${step})"

  local tpch_dir="tpch/sf${sf}"
  local tpcds_dir="tpcds/sf${sf}"

  mkdir -p "${tpch_dir}"
  mkdir -p "${tpcds_dir}"

  sed "s/%%SF%%/${sf}/g; s/%%CHILDREN%%/${children}/g; s/%%STEP%%/${step}/g" "$SQLFILE_STEP" | duckdb -bail -batch >/dev/null

  # Upload (and delete if requested) the step-based files to preserve disk space
  upload_and_delete_files "${tpch_dir}" "tpch/sf${sf}" "${step}" "${children}" "${delete_after}"
}

# Upload files and optionally delete them
upload_and_delete_files () {
  local local_dir="$1"
  local remote_path="$2"
  local step="${3:-}"
  local children="${4:-}"
  local delete_after="${5:-true}"

  local pattern="*.csv"
  if [[ -n "$step" && -n "$children" ]]; then
    pattern="*_${step}_${children}.csv"
  else
    # For base tables, we want to skip files that have the _step_children pattern
    # to avoid double processing if any were left over, though unlikely.
    # Actually, just matching all .csv that DON'T have a step/children pattern might be safer if we called it blindly,
    # but here we call it specifically.
    pattern="*.csv"
  fi

  shopt -s nullglob
  for csv in "${local_dir}"/${pattern}; do
    # Skip if it's a step file but we are in base mode
    if [[ -z "$step" && "$csv" =~ _[0-9]{4}_[0-9]{4}\.csv$ ]]; then
      continue
    fi

    local base_name
    base_name=$(basename "$csv" .csv)
    local zip_file="${base_name}.csv.zip"
    local parquet_file="${base_name}.parquet"

    echo "  Uploading and cleaning up ${base_name}"

    # Zip the CSV file
    (
      cd "${local_dir}"
      zip -q "${zip_file}" "${base_name}.csv"
    )

    # Upload to GCS
    gcloud storage cp --no-clobber "${local_dir}/${zip_file}" "gs://sql-arena-data/${remote_path}/" >/dev/null 2>&1 || true
    gcloud storage cp --no-clobber "${local_dir}/${parquet_file}" "gs://sql-arena-data/${remote_path}/" >/dev/null 2>&1 || true

    # Upload to S3
    aws s3 cp "${local_dir}/${zip_file}" "s3://sql-arena-data/${remote_path}/${zip_file}" >/dev/null 2>&1 || true
    aws s3 cp "${local_dir}/${parquet_file}" "s3://sql-arena-data/${remote_path}/${parquet_file}" >/dev/null 2>&1 || true

    # Delete local files if requested
    if [[ "$delete_after" == "true" ]]; then
      rm -f "${local_dir}/${base_name}.csv" "${local_dir}/${zip_file}" "${local_dir}/${parquet_file}"
    fi
  done
}

# Zip each CSV into its own .zip (next to the file)
# This is now handled within upload_and_delete_files

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

echo "Zipping and Uploading JOB CSV"
upload_and_delete_files "${JOB_DIR}" "job" "" "" "false"

# --- SF1 Generation ---
generate_tpc_base 1 "false"
generate_tpc_step 1 1 0 "false"

# --- SF1000 Generation (Steps 0 to 100) ---
generate_tpc_base 1000 "true"
for step in $(seq 0 100); do
  generate_tpc_step 1000 100 "$step" "true"
done

echo "Done."
