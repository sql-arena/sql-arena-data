# Build from the repo root: docker build -f docker/Dockerfile -t sql-arena-data .
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /opt/sql-arena-data
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    AWS_PROFILE_NAME=""

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project
RUN uv run --frozen python -c "import duckdb; duckdb.sql('INSTALL tpch; INSTALL tpcds')"

COPY . .

# Work files and DuckDB spill go here; mount a large disk on it
VOLUME /opt/sql-arena-data/temp

ENTRYPOINT ["uv", "run", "--frozen", "generate.py"]
