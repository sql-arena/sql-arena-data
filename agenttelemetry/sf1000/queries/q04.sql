/* Agent Telemetry Q04: daily cost and tokens by customer tier and model, last 30 days */
SELECT CAST(s.start_time AS DATE) AS day, t.tier, s.model, count(*) AS calls,
       sum(s.input_tokens) AS input_tokens, sum(s.output_tokens) AS output_tokens, sum(s.cost_usd) AS cost_usd
FROM agenttelemetry_sf1000.spans s
JOIN agenttelemetry_sf1000.tenants t ON t.tenant_id = s.tenant_id
WHERE s.kind = 'llm'
  AND s.start_time >= TIMESTAMPTZ '2025-12-02 00:00:00+00' AND s.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY day, t.tier, s.model
ORDER BY day, t.tier, s.model
