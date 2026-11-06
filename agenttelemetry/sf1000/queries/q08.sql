/* Agent Telemetry Q08: the 100 most expensive runs of the third quarter */
SELECT trace_id, tenant_id, agent_name, model, start_time, llm_calls, input_tokens, cost_usd
FROM agenttelemetry_sf1000.traces
WHERE start_time >= TIMESTAMPTZ '2025-07-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-10-01 00:00:00+00'
ORDER BY cost_usd DESC, trace_id
LIMIT 100
