/* Agent Telemetry Q28: web search latency and timeouts by hour on one day */
SELECT date_trunc('hour', start_time) AS hour, count(*) AS calls,
       quantile_cont(duration_ms, 0.5) AS p50_ms, quantile_cont(duration_ms, 0.95) AS p95_ms,
       count(*) FILTER (WHERE error_type = 'timeout') AS timeouts
FROM agenttelemetry_sf1000.spans
WHERE tool_name = 'web_search'
  AND start_time >= TIMESTAMPTZ '2025-07-08 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-07-11 00:00:00+00'
GROUP BY hour
ORDER BY hour
