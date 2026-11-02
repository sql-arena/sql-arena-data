/* Agent Telemetry Q09: tool facet, calls, error rate and p95 latency per tool, last 7 days */
SELECT tool_name, count(*) AS calls, avg(CASE WHEN status = 'ERROR' THEN 1.0 ELSE 0.0 END) AS error_rate,
       quantile_cont(duration_ms, 0.95) AS p95_ms
FROM agenttelemetry_sf10.spans
WHERE kind IN ('tool', 'retrieval')
  AND start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY tool_name
ORDER BY calls DESC, tool_name
