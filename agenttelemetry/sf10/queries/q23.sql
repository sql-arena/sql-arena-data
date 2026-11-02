/* Agent Telemetry Q23: LLM judge against human annotators, annotations of the fourth quarter */
SELECT CASE WHEN j.value >= 0.66 THEN 'high' WHEN j.value >= 0.4 THEN 'medium' ELSE 'low' END AS judge,
       h.label AS annotator, count(*) AS runs
FROM agenttelemetry_sf10.scores h
JOIN agenttelemetry_sf10.scores j ON j.trace_id = h.trace_id AND j.name = 'helpfulness'
    AND j.created_at >= TIMESTAMPTZ '2025-09-20 00:00:00+00'
WHERE h.name = 'correctness'
  AND h.created_at >= TIMESTAMPTZ '2025-10-01 00:00:00+00' AND h.created_at < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY judge, annotator
ORDER BY judge, annotator
