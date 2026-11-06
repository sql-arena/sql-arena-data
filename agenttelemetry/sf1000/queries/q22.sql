/* Agent Telemetry Q22: average judge score by model, for scores of the last 30 days */
SELECT t.model, count(*) AS scores, avg(s.value) AS helpfulness
FROM agenttelemetry_sf1000.scores s
JOIN agenttelemetry_sf1000.traces t ON t.trace_id = s.trace_id
    AND t.start_time >= TIMESTAMPTZ '2025-11-25 00:00:00+00' AND t.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
WHERE s.name = 'helpfulness'
  AND s.created_at >= TIMESTAMPTZ '2025-12-02 00:00:00+00' AND s.created_at < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY t.model
ORDER BY helpfulness DESC, t.model
