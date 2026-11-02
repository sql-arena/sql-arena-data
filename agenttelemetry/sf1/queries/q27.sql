/* Agent Telemetry Q27: December spend of the tenants that signed up in the second half of the year */
SELECT n.tenant_id, n.name, n.tier, n.created_at, count(*) AS runs, sum(t.cost_usd) AS cost_usd
FROM agenttelemetry_sf1.tenants n
JOIN agenttelemetry_sf1.traces t ON t.tenant_id = n.tenant_id
WHERE n.created_at >= TIMESTAMPTZ '2025-07-01 00:00:00+00'
  AND t.start_time >= TIMESTAMPTZ '2025-12-01 00:00:00+00' AND t.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY n.tenant_id, n.name, n.tier, n.created_at
ORDER BY cost_usd DESC, n.tenant_id
LIMIT 20
