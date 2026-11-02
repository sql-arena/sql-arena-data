/* Agent Telemetry Q13: needle with non-ASCII letters in the prompts of February */
SELECT trace_id, span_name, start_time
FROM agenttelemetry_sf10.spans
WHERE input_text LIKE '%Ærøskøbing%'
  AND start_time >= TIMESTAMPTZ '2025-02-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-03-01 00:00:00+00'
ORDER BY start_time, span_id
