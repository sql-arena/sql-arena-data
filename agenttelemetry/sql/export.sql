-- The exported tables of a chunk, in time order
CREATE OR REPLACE TABLE _export_spans AS
SELECT * EXCLUDE (_k, _d, _n, _o) FROM _spans ORDER BY start_time, span_id;

CREATE OR REPLACE TABLE _export_traces AS
SELECT r.trace_id, r.session_id, r.tenant_id, r.user_id, r.agent_name, r.environment, r.app_release, t.provider, t.model,
       r.start_time, r.end_time, r.duration_ms, r.status, r.error_type,
       a.span_count, a.llm_calls, a.tool_calls, a.tool_errors, a.input_tokens, a.output_tokens, a.cache_read_tokens,
       a.reasoning_tokens, a.cost_usd
FROM _spans r
JOIN _traces t ON t.tk = r._k
JOIN (
    SELECT trace_id, count(*) AS span_count, count(*) FILTER (WHERE kind = 'llm') AS llm_calls,
           count(*) FILTER (WHERE kind IN ('tool', 'retrieval')) AS tool_calls,
           count(*) FILTER (WHERE kind IN ('tool', 'retrieval') AND status = 'ERROR') AS tool_errors,
           sum(input_tokens)::BIGINT AS input_tokens, sum(output_tokens)::BIGINT AS output_tokens,
           sum(cache_read_tokens)::BIGINT AS cache_read_tokens, sum(reasoning_tokens)::BIGINT AS reasoning_tokens,
           sum(cost_usd)::DECIMAL(18, 9) AS cost_usd
    FROM _spans GROUP BY trace_id
) a ON a.trace_id = r.trace_id
WHERE r.parent_span_id IS NULL
ORDER BY r.start_time, r.trace_id;
