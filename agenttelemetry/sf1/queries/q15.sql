/* Agent Telemetry Q15: tool calls a model asked for, from its JSON output, against the tool spans that ran, last 7 days */
WITH requested AS (
    SELECT s.trace_id, json_extract_string(c.call, '$.id') AS tool_call_id,
           json_extract_string(c.call, '$.function.name') AS tool_name
    FROM agenttelemetry_sf1.spans s, unnest(json_extract(s.output_text, '$.tool_calls[*]')) AS c(call)
    WHERE s.kind = 'llm' AND s.finish_reason = 'tool_calls'
      AND s.start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND s.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
)
SELECT r.tool_name, count(*) AS requested, count(t.span_id) AS ran,
       count(*) FILTER (WHERE t.status = 'ERROR') AS failed
FROM requested r
LEFT JOIN agenttelemetry_sf1.spans t ON t.trace_id = r.trace_id AND t.tool_call_id = r.tool_call_id
    AND t.start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00'
GROUP BY r.tool_name
ORDER BY requested DESC, r.tool_name
