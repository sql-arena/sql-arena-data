/* Agent Telemetry Q20: first error of each failed run in the fourth quarter */
WITH first_error AS (
    SELECT trace_id, arg_min(kind, start_time) AS kind, arg_min(coalesce(tool_name, model), start_time) AS source,
           arg_min(error_type, start_time) AS error_type
    FROM agenttelemetry_sf10.spans
    WHERE status = 'ERROR' AND parent_span_id IS NOT NULL
      AND start_time >= TIMESTAMPTZ '2025-10-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
    GROUP BY trace_id
)
SELECT f.kind, f.source, f.error_type, count(*) AS runs,
       count(*) FILTER (WHERE t.status = 'ERROR') AS runs_failed
FROM first_error f
JOIN agenttelemetry_sf10.traces t ON t.trace_id = f.trace_id
    AND t.start_time >= TIMESTAMPTZ '2025-09-30 00:00:00+00' AND t.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY f.kind, f.source, f.error_type
ORDER BY runs DESC, f.kind, f.source, f.error_type
LIMIT 25
