/* Agent Telemetry Q19: incident drill-down, model call errors by type in 5-minute buckets */
SELECT time_bucket(INTERVAL '5 minutes', start_time) AS bucket, provider, error_type, count(*) AS calls
FROM agenttelemetry_sf1.spans
WHERE kind = 'llm' AND status = 'ERROR'
  AND start_time >= TIMESTAMPTZ '2025-09-02 12:00:00+00' AND start_time < TIMESTAMPTZ '2025-09-02 18:00:00+00'
GROUP BY bucket, provider, error_type
ORDER BY bucket, provider, error_type
