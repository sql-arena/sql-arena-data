CREATE OR REPLACE TABLE _export_tenants AS
SELECT tenant_id::INTEGER AS tenant_id, name, tier, region, created_at FROM _tenants ORDER BY tenant_id;

CREATE OR REPLACE TABLE _export_model_prices AS
SELECT p.provider, p.model, p.valid_from, p.input_price, p.output_price, p.cache_read_price, m.context_tokens
FROM _prices p JOIN _models m USING (model, provider) ORDER BY provider, model, valid_from;
