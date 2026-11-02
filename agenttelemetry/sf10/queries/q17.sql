/* Agent Telemetry Q17: sub-agent runs, the tokens and cost of their model calls by model, last 7 days */
SELECT m.model, count(DISTINCT a.span_id) AS subagent_runs, count(*) AS llm_calls,
       sum(m.input_tokens) AS input_tokens, sum(m.output_tokens) AS output_tokens, sum(m.cost_usd) AS cost_usd,
       avg(a.duration_ms) AS avg_run_ms
FROM agenttelemetry_sf10.spans a
JOIN agenttelemetry_sf10.spans m ON m.trace_id = a.trace_id AND m.parent_span_id = a.span_id AND m.kind = 'llm'
    AND m.start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00'
WHERE a.kind = 'agent' AND a.parent_span_id IS NOT NULL
  AND a.start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND a.start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY m.model
ORDER BY m.model
