/* Agent Telemetry Q32: the 20 runs of the last 7 days with the most failed tool calls, from their spans */
SELECT trace_id, count(*) AS spans,
       count(*) FILTER (WHERE kind IN ('tool', 'retrieval')) AS tool_calls,
       count(*) FILTER (WHERE kind IN ('tool', 'retrieval') AND status = 'ERROR') AS failed_tool_calls,
       sum(cost_usd) AS cost_usd
FROM %%NAMESPACE%%.spans
WHERE start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY trace_id
ORDER BY failed_tool_calls DESC, tool_calls DESC, trace_id
LIMIT 20
