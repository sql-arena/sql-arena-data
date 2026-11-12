/* Agent Telemetry Q31: incident search, the 50 tool results of the last 7 days that match most of four terms */
WITH matched AS (
    SELECT start_time, trace_id, span_id, tool_name,
           CASE WHEN output_text ILIKE '%billing%' THEN 1 ELSE 0 END
           + CASE WHEN output_text ILIKE '%connection refused%' THEN 1 ELSE 0 END
           + CASE WHEN output_text ILIKE '%timed out%' THEN 1 ELSE 0 END
           + CASE WHEN output_text ILIKE '%session-db%' THEN 1 ELSE 0 END AS score
    FROM %%NAMESPACE%%.spans
    WHERE kind IN ('tool', 'retrieval')
      AND start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
)
SELECT score, start_time, trace_id, span_id, tool_name
FROM matched
WHERE score > 0
ORDER BY score DESC, start_time DESC, span_id
LIMIT 50
