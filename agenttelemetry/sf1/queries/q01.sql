/* Agent Telemetry Q01: trace waterfall, all spans of one trace on its day */
SELECT span_id, parent_span_id, span_name, kind, start_time, duration_ms, status, error_type,
       input_tokens, output_tokens, cost_usd
FROM agenttelemetry_sf1.spans
WHERE trace_id = '921e2a502330c3c5a575a230009d95c1'
  AND start_time >= TIMESTAMPTZ '2025-10-28 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-10-29 00:00:00+00'
ORDER BY start_time, span_id
