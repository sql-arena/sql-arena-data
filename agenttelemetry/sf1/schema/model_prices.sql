CREATE TABLE agenttelemetry_sf1.model_prices (
    provider VARCHAR NOT NULL,
    model VARCHAR NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL,
    input_price DECIMAL(12,6) NOT NULL,
    output_price DECIMAL(12,6) NOT NULL,
    cache_read_price DECIMAL(12,6) NOT NULL,
    context_tokens INT NOT NULL
);
