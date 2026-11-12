/* Agent Telemetry Q30: the newest 50 tool results with any of five failure phrases, last 7 days */
SELECT start_time, trace_id, span_id, tool_name, status
FROM %%NAMESPACE%%.spans
WHERE kind IN ('tool', 'retrieval')
  AND (output_text ILIKE '%connection refused%' OR output_text ILIKE '%timed out%'
       OR output_text ILIKE '%permission denied%' OR output_text ILIKE '%Traceback%'
       OR output_text ILIKE '%no such file%')
  AND start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
ORDER BY start_time DESC, span_id
LIMIT 50
