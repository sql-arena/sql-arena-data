CREATE TABLE agenttelemetry_sf1000.tenants (
    tenant_id INT NOT NULL,
    name VARCHAR NOT NULL,
    tier VARCHAR NOT NULL,
    region VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);
