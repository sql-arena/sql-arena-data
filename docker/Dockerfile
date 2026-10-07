# Build from the repo root: docker build -f docker/Dockerfile -t sql-arena-data .

# dsdgen from the TPC-DS kit; keep the commit and compiler flags in step with tpcds/tpcds.py
FROM debian:bookworm-slim AS tpcds-kit
ARG TPCDS_KIT_COMMIT=5a3a81796992b725c2a8b216767e142609966752
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc make libc6-dev curl ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/kit.zip https://github.com/gregrahn/tpcds-kit/archive/${TPCDS_KIT_COMMIT}.zip \
    && unzip -q /tmp/kit.zip -d /tmp \
    && make -C /tmp/tpcds-kit-${TPCDS_KIT_COMMIT}/tools OS=LINUX dsdgen \
       CC="cc -std=gnu89 -Wno-implicit-int -Wno-implicit-function-declaration -Wno-int-conversion" \
    && mkdir /opt/tpcds-kit \
    && cp /tmp/tpcds-kit-${TPCDS_KIT_COMMIT}/tools/dsdgen /tmp/tpcds-kit-${TPCDS_KIT_COMMIT}/tools/tpcds.idx /opt/tpcds-kit/

FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /opt/sql-arena-data
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    AWS_PROFILE_NAME="" \
    TPCDS_KIT_DIR=/opt/tpcds-kit

COPY --from=tpcds-kit /opt/tpcds-kit /opt/tpcds-kit
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project
RUN uv run --frozen python -c "import duckdb; duckdb.sql('INSTALL tpch; INSTALL tpcds')"

COPY . .

# Work files and DuckDB spill go here; mount a large disk on it
VOLUME /opt/sql-arena-data/temp

ENTRYPOINT ["uv", "run", "--frozen", "generate.py"]
