# A worker: processes that generate chunks the coordinator hands out and insert them into S3 Tables. Build from the
# repo root: docker build -f agenttelemetry/demo/worker.Dockerfile .
FROM public.ecr.aws/docker/library/debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.13.7 /uv /uvx /bin/
ENV UV_PYTHON=3.12 UV_PYTHON_INSTALL_DIR=/opt/python UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
WORKDIR /app/repo
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY common common
COPY agenttelemetry agenttelemetry
RUN uv run --no-sync python -c "import duckdb; duckdb.connect().execute(open('agenttelemetry/demo/install-extensions.sql').read())"
# WORKER_ARGS takes further options of work, such as --processes 4
ENV COORDINATOR_URL=http://127.0.0.1:8080 WORKER_ARGS=""
CMD ["sh", "-c", "exec uv run --no-sync python -m agenttelemetry.s3tables work --coordinator \"$COORDINATOR_URL\" $WORKER_ARGS"]
