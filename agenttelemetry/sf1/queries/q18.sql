/* Agent Telemetry Q18: daily model call error rate by provider in March */
SELECT CAST(start_time AS DATE) AS day, provider, count(*) AS calls,
       count(*) FILTER (WHERE status = 'ERROR') AS errors,
       avg(CASE WHEN status = 'ERROR' THEN 1.0 ELSE 0.0 END) AS error_rate
FROM agenttelemetry_sf1.spans
WHERE kind = 'llm'
  AND start_time >= TIMESTAMPTZ '2025-03-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-04-01 00:00:00+00'
GROUP BY day, provider
ORDER BY day, provider
