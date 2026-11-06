CREATE TABLE agenttelemetry_sf1000.scores (
    score_id VARCHAR NOT NULL,
    trace_id VARCHAR NOT NULL,
    span_id VARCHAR NOT NULL,
    session_id VARCHAR NOT NULL,
    tenant_id INT NOT NULL,
    name VARCHAR NOT NULL,
    source VARCHAR NOT NULL,
    value DOUBLE NOT NULL,
    label VARCHAR NULL,
    comment VARCHAR NULL,
    created_at TIMESTAMPTZ NOT NULL
);
