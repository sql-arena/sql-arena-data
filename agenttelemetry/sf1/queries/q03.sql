/* Agent Telemetry Q03: hourly p50 and p95 model latency by model, last 24 hours */
SELECT date_trunc('hour', start_time) AS hour, model, count(*) AS calls,
       quantile_cont(duration_ms, 0.5) AS p50_ms, quantile_cont(duration_ms, 0.95) AS p95_ms
FROM agenttelemetry_sf1.spans
WHERE kind = 'llm'
  AND start_time >= TIMESTAMPTZ '2025-12-31 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY hour, model
ORDER BY hour, model
