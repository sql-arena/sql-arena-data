/* Agent Telemetry Q16: span tree depth of the runs of one hour, by recursive query */
WITH RECURSIVE window_spans AS (
    SELECT trace_id, span_id, parent_span_id, kind
    FROM agenttelemetry_sf1.spans
    WHERE start_time >= TIMESTAMPTZ '2025-12-31 15:00:00+00' AND start_time < TIMESTAMPTZ '2025-12-31 16:00:00+00'
), tree AS (
    SELECT trace_id, span_id, kind, 0 AS depth FROM window_spans WHERE parent_span_id IS NULL
    UNION ALL
    SELECT c.trace_id, c.span_id, c.kind, p.depth + 1
    FROM window_spans c
    JOIN tree p ON c.trace_id = p.trace_id AND c.parent_span_id = p.span_id
)
SELECT depth, kind, count(*) AS spans, count(DISTINCT trace_id) AS runs
FROM tree
GROUP BY depth, kind
ORDER BY depth, kind
