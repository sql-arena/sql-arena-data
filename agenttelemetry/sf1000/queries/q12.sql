/* Agent Telemetry Q12: case-insensitive phrase in tool results by tool, last 30 days */
SELECT tool_name, count(*) AS calls, count(DISTINCT trace_id) AS runs
FROM agenttelemetry_sf1000.spans
WHERE kind IN ('tool', 'retrieval') AND output_text ILIKE '%connection refused%'
  AND start_time >= TIMESTAMPTZ '2025-12-02 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY tool_name
ORDER BY calls DESC, tool_name
