/* Agent Telemetry Q02: session view, the runs of one session with their cost and tokens */
SELECT trace_id, start_time, duration_ms, status, model, llm_calls, tool_calls,
       input_tokens + output_tokens AS tokens, cost_usd
FROM agenttelemetry_sf1000.traces
WHERE session_id = '1ed248067075d77e9611bb48b01a9f8f'
  AND start_time >= TIMESTAMPTZ '2025-10-27 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-10-30 00:00:00+00'
ORDER BY start_time
