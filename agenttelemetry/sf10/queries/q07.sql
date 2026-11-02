/* Agent Telemetry Q07: top 20 users by cost in November */
SELECT user_id, tenant_id, count(*) AS runs, sum(cost_usd) AS cost_usd, sum(input_tokens + output_tokens) AS tokens
FROM agenttelemetry_sf10.traces
WHERE start_time >= TIMESTAMPTZ '2025-11-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-12-01 00:00:00+00'
GROUP BY user_id, tenant_id
ORDER BY cost_usd DESC, user_id
LIMIT 20
