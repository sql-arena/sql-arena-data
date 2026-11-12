# The coordinator: the web app, which plans runs and hands out chunks. Build from the repo root:
# docker build -f agenttelemetry/demo/coordinator.Dockerfile .
FROM public.ecr.aws/docker/library/node:24-bookworm-slim AS web
WORKDIR /web
COPY agenttelemetry/demo/web/package.json agenttelemetry/demo/web/package-lock.json ./
RUN npm ci
COPY agenttelemetry/demo/web ./
RUN npm run check && npm test && npm run build && npm prune --omit=dev

FROM public.ecr.aws/docker/library/node:24-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.13.7 /uv /uvx /bin/
ENV UV_PYTHON=3.12 UV_PYTHON_INSTALL_DIR=/opt/python UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
WORKDIR /app/repo
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY common common
COPY agenttelemetry agenttelemetry
COPY --from=web /web/package.json /app/web/package.json
COPY --from=web /web/node_modules /app/web/node_modules
COPY --from=web /web/build /app/web/build
# The Python and Node DuckDB differ in version, so each installs its own extensions
RUN uv run --no-sync python -c "import duckdb; duckdb.connect().execute(open('agenttelemetry/demo/install-extensions.sql').read())" \
 && cd /app/web && node -e "import('@duckdb/node-api').then(async ({ DuckDBInstance }) => { const c = await (await DuckDBInstance.create()).connect(); await c.run(require('fs').readFileSync('/app/repo/agenttelemetry/demo/install-extensions.sql', 'utf8')); })"
ENV REPO_DIR=/app/repo STATUS_DIR=/data HOST=127.0.0.1 PORT=8080 ORIGIN=http://localhost:8080
VOLUME /data
CMD ["node", "/app/web/build"]
