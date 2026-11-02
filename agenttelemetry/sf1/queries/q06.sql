/* Agent Telemetry Q06: trace list, second page of one tenant's slowest runs of the last 24 hours, with scores */
SELECT t.trace_id, t.start_time, t.agent_name, t.duration_ms, t.status, t.cost_usd,
       avg(s.value) FILTER (WHERE s.name = 'helpfulness') AS helpfulness,
       max(s.label) FILTER (WHERE s.name = 'user_feedback') AS feedback
FROM agenttelemetry_sf1.traces t
LEFT JOIN agenttelemetry_sf1.scores s ON s.trace_id = t.trace_id AND s.created_at >= TIMESTAMPTZ '2025-12-31 00:00:00+00'
WHERE t.tenant_id = 1
  AND t.start_time >= TIMESTAMPTZ '2025-12-31 00:00:00+00' AND t.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY t.trace_id, t.start_time, t.agent_name, t.duration_ms, t.status, t.cost_usd
ORDER BY t.duration_ms DESC, t.trace_id
LIMIT 50 OFFSET 50
