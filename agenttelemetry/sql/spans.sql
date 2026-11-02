-- The spans of _traces. An agent run is a root agent span with, per turn, a model call (llm) and the tool calls it
-- asks for, run one after another. A task tool call runs a sub-agent of a small model below it.

CREATE OR REPLACE MACRO user_task(agent_name, k) AS CASE agent_name
    WHEN 'coding-agent' THEN 'Fix this in ' || word(getvariable('path'), 'tp|' || k) || ':'
    WHEN 'support-agent' THEN 'Customer ticket #' || pick('tn|' || k, 999999) || ':'
    WHEN 'research-agent' THEN 'Research question:'
    WHEN 'data-agent' THEN 'Analyse the ' || word(getvariable('nouns'), 'tt|' || k) || 's table:'
    ELSE 'Alert fired on ' || word(getvariable('services'), 'ts|' || k) || ':' END
    || ' ' || run(getvariable('prose'), 'task|' || k, pick('tl|' || k, 3)::INTEGER);

-- Turns of each trace
CREATE OR REPLACE TEMP TABLE _turns AS
SELECT *,
       CASE WHEN last_turn THEN 0 ELSE 1 + (rnd('nt1|' || uk) < 0.35)::INTEGER + (rnd('nt2|' || uk) < 0.1)::INTEGER END AS tool_count,
       CASE WHEN last_turn THEN 200 + floor(rnd('out|' || uk) * 1300) ELSE 30 + floor(rnd('out|' || uk) * 570) END::BIGINT AS output_tokens,
       run(getvariable('prose'), 'say|' || uk, CASE WHEN last_turn THEN 3 + pick('sl|' || uk, 5) ELSE pick('sl|' || uk, 2) END::INTEGER) AS content
FROM (
    SELECT tr.*, t, t = turns - 1 AS last_turn, tk || '|' || t AS uk,
           CASE WHEN has_subagent AND turns > 1 THEN pick('subturn|' || tk, turns - 1) - 1 END AS subagent_turn
    FROM _traces tr, LATERAL (SELECT unnest(range(tr.turns)) AS t)
);

-- Tool calls, with their arguments, result and failures
CREATE OR REPLACE TEMP TABLE _calls AS
WITH calls AS (
    SELECT u.tk, u.uk, u.t, j, u.uk || '|' || j AS ck, u.trace_start, u.app_release, u.agent_name,
           CASE WHEN u.t = u.subagent_turn AND j = 0 THEN 'task'
                ELSE u.agent_tools[pick('tool|' || u.uk || '|' || j, len(u.agent_tools))] END AS tool_name
    FROM _turns u, LATERAL (SELECT unnest(range(u.tool_count)) AS j)
)
SELECT c.*, tl.kind, 'toolu_' || hex_id('call|' || c.ck, 24) AS tool_call_id,
       tl.min_lines + pick('lines|' || c.ck, tl.max_lines - tl.min_lines + 1) - 1 AS lines,
       rnd('fail|' || c.ck) < tl.error_rate + coalesce(i.error_rate, 0)
           + CASE WHEN c.tool_name = 'edit_file' AND c.app_release = getvariable('bad_release') THEN 0.3 ELSE 0 END AS failed,
       coalesce(i.error_type, tl.error_type) AS error_type, coalesce(i.error_type || ': ', '') || tl.error_message AS error_message,
       tl.median_ms * exp((rnd('ms|' || c.ck) - 0.5) * 1.6) * coalesce(i.latency_factor, 1) AS tool_ms,
       tl.pool,
       CASE c.tool_name
           WHEN 'read_file' THEN json_object('path', word(getvariable('path'), 'p|' || c.ck))
           WHEN 'edit_file' THEN json_object('path', word(getvariable('path'), 'p|' || c.ck),
                                             'old_string', run(getvariable('code'), 'old|' || c.ck, 2),
                                             'new_string', run(getvariable('code'), 'new|' || c.ck, 3))
           WHEN 'bash' THEN json_object('command', ['pytest -x ', 'make test ', 'git diff ', 'npm run build ', 'tail -n 200 '][pick('cmd|' || c.ck, 5)]
                                                   || word(getvariable('path'), 'p|' || c.ck))
           WHEN 'grep' THEN json_object('pattern', word(getvariable('verbs'), 'g1|' || c.ck) || '_' || word(getvariable('nouns'), 'g2|' || c.ck), 'path', 'src/')
           WHEN 'glob' THEN json_object('pattern', '**/*' || word(getvariable('nouns'), 'g3|' || c.ck) || '*')
           WHEN 'web_fetch' THEN json_object('url', split_part(word(getvariable('url'), 'w|' || c.ck), ' - ', 2))
           WHEN 'read_pdf' THEN json_object('url', 'https://papers.example.org/' || pick('pdf|' || c.ck, 99999) || '.pdf')
           WHEN 'web_search' THEN json_object('query', word(getvariable('adjectives'), 'q1|' || c.ck) || ' ' || word(getvariable('nouns'), 'q2|' || c.ck) || ' ' || word(getvariable('verbs'), 'q3|' || c.ck))
           WHEN 'search_kb' THEN json_object('query', word(getvariable('nouns'), 'q4|' || c.ck) || ' ' || word(getvariable('adjectives'), 'q5|' || c.ck))
           WHEN 'get_ticket' THEN json_object('ticket_id', pick('tid|' || c.ck, 999999))
           WHEN 'update_ticket' THEN json_object('ticket_id', pick('tid|' || c.ck, 999999), 'status', ['pending', 'solved', 'escalated'][pick('ts|' || c.ck, 3)])
           WHEN 'lookup_order' THEN json_object('order_id', pick('oid|' || c.ck, 9999999))
           WHEN 'send_email' THEN json_object('to', 'customer' || pick('to|' || c.ck, 99999) || '@example.com', 'subject', 'Re: your ' || word(getvariable('nouns'), 'subj|' || c.ck))
           WHEN 'list_tables' THEN json_object('schema', ['sales', 'ops', 'billing', 'events'][pick('sch|' || c.ck, 4)])
           WHEN 'describe_table' THEN json_object('table', ['sales', 'ops', 'billing', 'events'][pick('sch|' || c.ck, 4)] || '.' || word(getvariable('nouns'), 'tb|' || c.ck) || 's')
           WHEN 'sql_query' THEN json_object('sql', word(getvariable('sql'), 'sql|' || c.ck))
           WHEN 'run_python' THEN json_object('code', run(getvariable('code'), 'py|' || c.ck, pick('pyl|' || c.ck, 12)::INTEGER))
           WHEN 'query_logs' THEN json_object('service', word(getvariable('services'), 'svc|' || c.ck), 'query', 'level:ERROR', 'since', '1h')
           WHEN 'get_metrics' THEN json_object('metric', word(getvariable('services'), 'svc|' || c.ck) || '.latency_p95', 'window', '6h')
           WHEN 'kubectl' THEN json_object('args', ['get pods -n ', 'logs deploy/', 'describe deploy/', 'rollout status deploy/'][pick('k|' || c.ck, 4)] || word(getvariable('services'), 'svc|' || c.ck))
           WHEN 'page_oncall' THEN json_object('team', word(getvariable('services'), 'svc|' || c.ck), 'severity', 'SEV' || pick('sev|' || c.ck, 3))
           WHEN 'task' THEN json_object('description', run(getvariable('prose'), 'td|' || c.ck, 2))
       END::VARCHAR AS input_text
FROM calls c
JOIN _tools tl USING (tool_name)
LEFT JOIN _incidents i ON i.tool_name = c.tool_name AND c.trace_start >= i.starts AND c.trace_start < i.ends;

CREATE OR REPLACE TEMP TABLE _calls AS
SELECT * EXCLUDE (pool, lines, failed, error_type, error_message),
       CASE WHEN failed THEN 'ERROR' ELSE 'OK' END AS status,
       CASE WHEN failed THEN error_type END AS error_type,
       CASE WHEN failed THEN error_message
            WHEN tool_name = 'edit_file' THEN 'The file ' || (input_text::JSON ->> 'path') || ' has been updated.'
            WHEN tool_name = 'update_ticket' THEN 'Ticket ' || (input_text::JSON ->> 'ticket_id') || ' updated.'
            WHEN tool_name = 'send_email' THEN 'Email queued with message id <' || hex_id('mid|' || ck, 20) || '@mail.example.com>'
            WHEN tool_name = 'page_oncall' THEN 'Paged on-call, incident INC-' || pick('inc|' || ck, 99999)
            ELSE pool_run(pool, 'out|' || ck, lines::INTEGER) END AS output_text
FROM _calls;

-- Needles for text search, the same rows at every scale factor: a leaked key in one command's output, an error code in
-- the logs of each day of one week, and a place name with non-ASCII letters in one task (the key is split so secret scanners do not flag the source)
UPDATE _calls SET output_text = output_text || chr(10) || 'export PAYMENTS_API_KEY=sk_' || 'live_51HxArena7f3b9c2d4e6a8b0c1d2e3f'
WHERE ck = (SELECT c.ck FROM _calls c JOIN _traces t USING (tk)
            WHERE c.tool_name = 'bash' AND c.status = 'OK' AND t.d = 162 AND t.turns > c.t + 1 ORDER BY t.n, t.i, c.t, c.j LIMIT 1);
UPDATE _calls SET output_text = output_text || chr(10) || 'ERROR [billing] ERR_LEDGER_SHARD_7731: ledger shard 7731 rejected write, replica lag 912s'
WHERE ck IN (SELECT arg_min(c.ck, (t.n, t.i, c.t, c.j)) FROM _calls c JOIN _traces t USING (tk)
             WHERE c.tool_name = 'query_logs' AND c.status = 'OK' AND t.d BETWEEN 278 AND 284 AND t.turns > c.t + 1 GROUP BY t.d);

-- Sub-agents: 2 to 5 turns of the provider's small model, each but the last calling one tool
CREATE OR REPLACE TEMP TABLE _sub AS
SELECT c.tk, c.ck, c.tool_call_id AS parent_call, s, s = sub_turns - 1 AS last_turn, c.ck || '|' || s AS sk,
       CASE WHEN tr.d >= coalesce(sm.released_day, -1) THEN sm.model ELSE tr.model END AS model,
       CASE WHEN s = sub_turns - 1 THEN NULL
            WHEN c.agent_name = 'research-agent' THEN ['web_search', 'web_fetch'][pick('st|' || c.ck || '|' || s, 2)]
            ELSE ['read_file', 'grep', 'glob'][pick('st|' || c.ck || '|' || s, 3)] END AS tool_name
FROM _calls c
JOIN _traces tr USING (tk)
JOIN _models m ON m.model = tr.model
JOIN _models sm ON sm.model = m.small_model,
LATERAL (SELECT 1 + pick('sturns|' || c.ck, 4) AS sub_turns),
LATERAL (SELECT unnest(range(sub_turns)) AS s)
WHERE c.tool_name = 'task';

-- Sub-agent tool calls
CREATE OR REPLACE TEMP TABLE _sub_calls AS
SELECT s.sk, s.ck, s.s, s.tool_name, tl.kind, 'toolu_' || hex_id('call|' || s.sk, 24) AS tool_call_id,
       CASE s.tool_name
           WHEN 'read_file' THEN json_object('path', word(getvariable('path'), 'p|' || s.sk))
           WHEN 'grep' THEN json_object('pattern', word(getvariable('verbs'), 'g1|' || s.sk) || '_' || word(getvariable('nouns'), 'g2|' || s.sk), 'path', 'src/')
           WHEN 'glob' THEN json_object('pattern', '**/*' || word(getvariable('nouns'), 'g3|' || s.sk) || '*')
           WHEN 'web_fetch' THEN json_object('url', split_part(word(getvariable('url'), 'w|' || s.sk), ' - ', 2))
           WHEN 'web_search' THEN json_object('query', word(getvariable('adjectives'), 'q1|' || s.sk) || ' ' || word(getvariable('nouns'), 'q2|' || s.sk))
       END::VARCHAR AS input_text,
       pool_run(tl.pool, 'out|' || s.sk, (tl.min_lines + pick('lines|' || s.sk, tl.max_lines - tl.min_lines + 1) - 1)::INTEGER) AS output_text,
       tl.median_ms * exp((rnd('ms|' || s.sk) - 0.5) * 1.6) AS tool_ms
FROM _sub s
JOIN _tools tl USING (tool_name);

-- What each trace's model calls start from: the system prompt with tool definitions, and the user's task
CREATE OR REPLACE TEMP TABLE _prompts AS
SELECT tk, user_task(agent_name, tk) AS task,
       run(getvariable('prose'), 'system|' || agent_name || '|' || prompt_version, 25) AS system_prompt
FROM _traces;

UPDATE _prompts SET task = task || ' The customer lives in Ærøskøbing, Denmark.'
WHERE tk = (SELECT tk FROM _traces WHERE agent_name = 'support-agent' AND d = 33 ORDER BY n, i LIMIT 1);

-- Model calls: each one is sent the whole conversation so far, and providers other than initech cache the earlier
-- turns. A call fails when the conversation outgrows the model's context, when the provider has an incident, or by
-- chance; the run then ends with that call.
CREATE OR REPLACE TEMP TABLE _llm AS
WITH results AS (
    SELECT uk, sum(ceil(len(output_text) / 4) + 20)::BIGINT AS result_tokens FROM _calls GROUP BY uk
), tokens AS (
    SELECT u.*, m.context_tokens, m.tokens_per_second, i.error_type AS incident_error, coalesce(i.error_rate, 0) AS incident_rate,
           u.tool_definition_tokens + ceil(len(p.system_prompt) / 4)::BIGINT AS system_tokens,
           u.tool_definition_tokens + ceil(len(p.system_prompt) / 4)::BIGINT + ceil(len(p.task) / 4)::BIGINT
               + coalesce(sum(u.output_tokens + coalesce(r.result_tokens, 0)) OVER (PARTITION BY u.tk ORDER BY u.t ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)::BIGINT AS input_tokens,
           CASE WHEN m.reasoning THEN 200 + floor(rnd('reasoning|' || u.uk) * 3800)::BIGINT ELSE 0 END AS reasoning_tokens
    FROM _turns u
    JOIN _prompts p USING (tk)
    JOIN _models m ON m.model = u.model
    LEFT JOIN results r USING (uk)
    LEFT JOIN _incidents i ON i.provider = u.provider AND u.trace_start >= i.starts AND u.trace_start < i.ends
), failures AS (
    SELECT *,
           CASE WHEN input_tokens > context_tokens THEN 'context_length_exceeded'
                WHEN rnd('llmfail|' || uk) < incident_rate THEN incident_error
                WHEN rnd('llmfail|' || uk) < incident_rate + 0.004
                    THEN ['rate_limit_error', 'rate_limit_error', 'overloaded_error', 'server_error'][pick('llmerr|' || uk, 4)] END AS error_type,
           CASE WHEN provider = 'initech' THEN 0
                WHEN t > 0 THEN lag(input_tokens) OVER (PARTITION BY tk ORDER BY t)
                WHEN i > 0 THEN system_tokens ELSE 0 END AS cache_read_tokens
    FROM tokens
)
SELECT *, min(t) FILTER (WHERE error_type IS NOT NULL) OVER (PARTITION BY tk) AS failed_turn FROM failures;

DELETE FROM _llm WHERE t > failed_turn;
DELETE FROM _calls c USING _llm l WHERE c.uk = l.uk AND l.error_type IS NOT NULL;
DELETE FROM _calls c WHERE NOT EXISTS (SELECT 1 FROM _llm l WHERE l.uk = c.uk);
DELETE FROM _sub s WHERE NOT EXISTS (SELECT 1 FROM _calls c WHERE c.ck = s.ck);
DELETE FROM _sub_calls s WHERE NOT EXISTS (SELECT 1 FROM _calls c WHERE c.ck = s.ck);

-- Sub-agent model calls, which see their task and the earlier turns
CREATE OR REPLACE TEMP TABLE _sub_llm AS
SELECT s.*, m.provider, m.tokens_per_second,
       1200 + coalesce(sum(o.output_tokens + ceil(len(coalesce(sc.output_text, '')) / 4) + 20)
                       OVER (PARTITION BY s.ck ORDER BY s.s ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)::BIGINT AS input_tokens,
       o.output_tokens,
       CASE WHEN m.reasoning THEN 100 + floor(rnd('reasoning|' || s.sk) * 1900)::BIGINT ELSE 0 END AS reasoning_tokens,
       run(getvariable('prose'), 'say|' || s.sk, CASE WHEN s.last_turn THEN 4 ELSE 1 END) AS content
FROM _sub s
JOIN _models m USING (model)
LEFT JOIN _sub_calls sc USING (sk),
LATERAL (SELECT CASE WHEN s.last_turn THEN 150 + floor(rnd('out|' || s.sk) * 600) ELSE 30 + floor(rnd('out|' || s.sk) * 200) END::BIGINT AS output_tokens) o;

CREATE OR REPLACE MACRO llm_ms(input_tokens, output_tokens, reasoning_tokens, tokens_per_second, k) AS
    250 + input_tokens * 0.004 + rnd('ttft|' || k) * 600
    + (output_tokens + reasoning_tokens) * 1000.0 / tokens_per_second * (0.7 + 0.6 * rnd('tps|' || k));

-- Timeline: a sub-agent's calls run one after the other inside its task call, and so do a run's turns and tool calls
CREATE OR REPLACE TEMP TABLE _sub_times AS
SELECT *, 5 + sum(ms + 10) OVER (PARTITION BY ck ORDER BY o ROWS UNBOUNDED PRECEDING) - ms - 10 AS offset_ms
FROM (
    SELECT ck, sk AS item, s * 2 AS o, llm_ms(input_tokens, output_tokens, reasoning_tokens, tokens_per_second, sk) AS ms FROM _sub_llm
    UNION ALL
    SELECT ck, sk || '|tool', s * 2 + 1, tool_ms FROM _sub_calls
);

CREATE OR REPLACE TEMP TABLE _times AS
SELECT *, 15 + sum(ms + 10) OVER (PARTITION BY tk ORDER BY o ROWS UNBOUNDED PRECEDING) - ms - 10 AS offset_ms
FROM (
    SELECT tk, uk AS item, t * 10 AS o,
           CASE WHEN error_type = 'context_length_exceeded' THEN 150 + rnd('ms|' || uk) * 100
                WHEN error_type IS NOT NULL THEN 200 + rnd('ms|' || uk) * 3000
                ELSE llm_ms(input_tokens, output_tokens, reasoning_tokens, tokens_per_second, uk) END AS ms
    FROM _llm
    UNION ALL
    SELECT c.tk, c.ck, c.t * 10 + 1 + c.j,
           coalesce((SELECT max(st.offset_ms + st.ms) + 10 FROM _sub_times st WHERE st.ck = c.ck), c.tool_ms)
    FROM _calls c
);

CREATE OR REPLACE MACRO at_ms(start, ms) AS start + to_microseconds(round(ms * 1000)::BIGINT);

CREATE OR REPLACE MACRO common_attributes(t) AS json_object(
    'service.name', t.agent_name, 'deployment.environment', t.environment, 'deployment.region', t.region,
    'customer.tier', t.tier, 'app.release', t.app_release);
CREATE OR REPLACE MACRO llm_attributes(t, provider, k) AS json_merge_patch(common_attributes(t), json_object(
    'gen_ai.operation.name', 'chat', 'gen_ai.request.max_tokens', 8192,
    'gen_ai.request.temperature', CASE t.agent_name WHEN 'research-agent' THEN 0.7 WHEN 'support-agent' THEN 0.3 ELSE 0.0 END,
    'gen_ai.response.id', 'msg_' || hex_id('response|' || k, 24), 'server.address', provider || '.api.example.com'));
CREATE OR REPLACE MACRO tool_attributes(t, tool_call_id) AS json_merge_patch(common_attributes(t), json_object(
    'gen_ai.operation.name', 'execute_tool', 'gen_ai.tool.type', 'function', 'gen_ai.tool.call.id', tool_call_id));
CREATE OR REPLACE MACRO assistant(content, tool_calls) AS CASE WHEN len(tool_calls) = 0
    THEN to_json({'role': 'assistant', 'content': content})
    ELSE to_json({'role': 'assistant', 'content': content, 'tool_calls': tool_calls}) END::VARCHAR;
CREATE OR REPLACE MACRO tool_call(id, name, arguments) AS {'id': id, 'type': 'function', 'function': {'name': name, 'arguments': arguments}};
CREATE OR REPLACE MACRO message(role, tool_call_id, content) AS {'role': role, 'tool_call_id': tool_call_id, 'content': content};

CREATE OR REPLACE TEMP TABLE _spans (
    trace_id VARCHAR NOT NULL, span_id VARCHAR NOT NULL, parent_span_id VARCHAR, session_id VARCHAR NOT NULL,
    tenant_id INTEGER NOT NULL, user_id VARCHAR NOT NULL, environment VARCHAR NOT NULL, app_release VARCHAR NOT NULL,
    span_name VARCHAR NOT NULL, kind VARCHAR NOT NULL, agent_name VARCHAR NOT NULL, tool_name VARCHAR, tool_call_id VARCHAR,
    provider VARCHAR, model VARCHAR, start_time TIMESTAMPTZ NOT NULL, end_time TIMESTAMPTZ NOT NULL,
    first_token_time TIMESTAMPTZ, duration_ms BIGINT NOT NULL, status VARCHAR NOT NULL, error_type VARCHAR,
    finish_reason VARCHAR, input_tokens BIGINT, output_tokens BIGINT, cache_read_tokens BIGINT, reasoning_tokens BIGINT,
    cost_usd DECIMAL(18, 9), prompt_name VARCHAR, prompt_version INTEGER, attributes VARCHAR NOT NULL,
    input_text VARCHAR, output_text VARCHAR,
    -- Generation keys, dropped on export
    _k VARCHAR NOT NULL, _d INTEGER NOT NULL, _n BIGINT NOT NULL, _o INTEGER NOT NULL
);

-- Agent runs
INSERT INTO _spans BY NAME
SELECT tr.trace_id, hex_id('span|' || tr.tk, 16) AS span_id, tr.session_id, tr.tenant_id, tr.user_id, tr.environment,
       tr.app_release, 'invoke_agent ' || tr.agent_name AS span_name, 'agent' AS kind, tr.agent_name,
       tr.trace_start AS start_time, at_ms(tr.trace_start, e.end_ms) AS end_time, round(e.end_ms)::BIGINT AS duration_ms,
       CASE WHEN f.error_type IS NULL THEN 'OK' ELSE 'ERROR' END AS status, f.error_type,
       json_merge_patch(common_attributes(tr), json_object('gen_ai.operation.name', 'invoke_agent', 'session.trace_index', tr.i),
                        CASE WHEN tr.feature_flags IS NOT NULL THEN json_object('feature.flags', tr.feature_flags) ELSE '{}' END,
                        CASE WHEN tr.experiment IS NOT NULL THEN json_object('experiment.id', tr.experiment) ELSE '{}' END)::VARCHAR AS attributes,
       to_json([message('user', NULL, p.task)])::VARCHAR AS input_text, f.final_content AS output_text,
       tr.tk AS _k, tr.d AS _d, tr.n AS _n, -1 AS _o
FROM _traces tr
JOIN _prompts p USING (tk)
JOIN (SELECT tk, max(offset_ms + ms) + 15 AS end_ms FROM _times GROUP BY tk) e USING (tk)
JOIN (SELECT tk, max(error_type) AS error_type, max(content) FILTER (WHERE last_turn AND error_type IS NULL) AS final_content
      FROM _llm GROUP BY tk) f USING (tk);

-- Model calls of agent runs
INSERT INTO _spans BY NAME
SELECT l.trace_id, hex_id('span|' || l.uk, 16) AS span_id, hex_id('span|' || l.tk, 16) AS parent_span_id, l.session_id,
       l.tenant_id, l.user_id, l.environment, l.app_release, 'chat ' || l.model AS span_name, 'llm' AS kind, l.agent_name,
       l.provider, l.model, at_ms(l.trace_start, tm.offset_ms) AS start_time, at_ms(l.trace_start, tm.offset_ms + tm.ms) AS end_time,
       CASE WHEN l.error_type IS NULL THEN at_ms(l.trace_start, tm.offset_ms + 250 + l.input_tokens * 0.004 + rnd('ttft|' || l.uk) * 600) END AS first_token_time,
       round(tm.ms)::BIGINT AS duration_ms,
       CASE WHEN l.error_type IS NULL THEN 'OK' ELSE 'ERROR' END AS status, l.error_type,
       CASE WHEN l.error_type IS NOT NULL THEN 'error' WHEN l.tool_count > 0 THEN 'tool_calls' ELSE 'stop' END AS finish_reason,
       l.input_tokens, CASE WHEN l.error_type IS NULL THEN l.output_tokens ELSE 0 END AS output_tokens, l.cache_read_tokens,
       CASE WHEN l.error_type IS NULL THEN l.reasoning_tokens ELSE 0 END AS reasoning_tokens,
       l.agent_name || '-system' AS prompt_name, l.prompt_version,
       llm_attributes(l, l.provider, l.uk)::VARCHAR AS attributes,
       CASE WHEN l.t = 0 THEN to_json([message('system', NULL, p.system_prompt), message('user', NULL, p.task)])::VARCHAR
            ELSE (SELECT to_json(list(message('tool', c.tool_call_id, c.output_text) ORDER BY c.j))::VARCHAR
                  FROM _calls c WHERE c.uk = l.tk || '|' || (l.t - 1)) END AS input_text,
       CASE WHEN l.error_type IS NULL THEN assistant(l.content, coalesce(
           (SELECT list(tool_call(c.tool_call_id, c.tool_name, c.input_text) ORDER BY c.j) FROM _calls c WHERE c.uk = l.uk), [])) END AS output_text,
       l.tk AS _k, l.d AS _d, l.n AS _n, tm.o AS _o
FROM _llm l
JOIN _prompts p USING (tk)
JOIN _times tm ON tm.item = l.uk;

-- Tool calls of agent runs
INSERT INTO _spans BY NAME
SELECT tr.trace_id, hex_id('span|' || c.ck, 16) AS span_id, hex_id('span|' || c.tk, 16) AS parent_span_id, tr.session_id,
       tr.tenant_id, tr.user_id, tr.environment, tr.app_release, 'execute_tool ' || c.tool_name AS span_name, c.kind,
       tr.agent_name, c.tool_name, c.tool_call_id,
       at_ms(tr.trace_start, tm.offset_ms) AS start_time, at_ms(tr.trace_start, tm.offset_ms + tm.ms) AS end_time,
       round(tm.ms)::BIGINT AS duration_ms, c.status, c.error_type,
       tool_attributes(tr, c.tool_call_id)::VARCHAR AS attributes, c.input_text, c.output_text,
       tr.tk AS _k, tr.d AS _d, tr.n AS _n, tm.o AS _o
FROM _calls c
JOIN _traces tr USING (tk)
JOIN _times tm ON tm.item = c.ck;

-- Sub-agent runs, below their task call
INSERT INTO _spans BY NAME
SELECT tr.trace_id, hex_id('span|' || c.ck || '|agent', 16) AS span_id, hex_id('span|' || c.ck, 16) AS parent_span_id,
       tr.session_id, tr.tenant_id, tr.user_id, tr.environment, tr.app_release, 'invoke_agent explorer' AS span_name,
       'agent' AS kind, 'explorer' AS agent_name,
       at_ms(tr.trace_start, tm.offset_ms + 2) AS start_time, at_ms(tr.trace_start, tm.offset_ms + tm.ms - 2) AS end_time,
       round(tm.ms - 4)::BIGINT AS duration_ms, 'OK' AS status,
       json_merge_patch(common_attributes(tr), json_object('gen_ai.operation.name', 'invoke_agent', 'gen_ai.agent.name', 'explorer'))::VARCHAR AS attributes,
       to_json([message('user', NULL, c.input_text::JSON ->> 'description')])::VARCHAR AS input_text,
       (SELECT content FROM _sub_llm s WHERE s.ck = c.ck AND s.last_turn) AS output_text,
       tr.tk AS _k, tr.d AS _d, tr.n AS _n, tm.o AS _o
FROM _calls c
JOIN _traces tr USING (tk)
JOIN _times tm ON tm.item = c.ck
WHERE c.tool_name = 'task';

-- Sub-agent model calls and tool calls
INSERT INTO _spans BY NAME
SELECT tr.trace_id, hex_id('span|' || s.sk, 16) AS span_id, hex_id('span|' || s.ck || '|agent', 16) AS parent_span_id,
       tr.session_id, tr.tenant_id, tr.user_id, tr.environment, tr.app_release, 'chat ' || s.model AS span_name, 'llm' AS kind,
       'explorer' AS agent_name, s.provider, s.model,
       at_ms(tr.trace_start, ct.offset_ms + st.offset_ms) AS start_time, at_ms(tr.trace_start, ct.offset_ms + st.offset_ms + st.ms) AS end_time,
       at_ms(tr.trace_start, ct.offset_ms + st.offset_ms + 250 + s.input_tokens * 0.004 + rnd('ttft|' || s.sk) * 600) AS first_token_time,
       round(st.ms)::BIGINT AS duration_ms, 'OK' AS status, CASE WHEN s.last_turn THEN 'stop' ELSE 'tool_calls' END AS finish_reason,
       s.input_tokens, s.output_tokens, CASE WHEN s.provider = 'initech' OR s.s = 0 THEN 0 ELSE s.input_tokens - 400 END AS cache_read_tokens,
       s.reasoning_tokens, 'explorer-system' AS prompt_name, 1 AS prompt_version,
       llm_attributes(tr, s.provider, s.sk)::VARCHAR AS attributes,
       CASE WHEN s.s = 0 THEN to_json([message('system', NULL, run(getvariable('prose'), 'system|explorer', 10)),
                                       message('user', NULL, c.input_text::JSON ->> 'description')])::VARCHAR
            ELSE (SELECT to_json([message('tool', p.tool_call_id, p.output_text)])::VARCHAR FROM _sub_calls p
                  WHERE p.ck = s.ck AND p.s = s.s - 1) END AS input_text,
       assistant(s.content, coalesce((SELECT [tool_call(sc.tool_call_id, sc.tool_name, sc.input_text)] FROM _sub_calls sc WHERE sc.sk = s.sk), [])) AS output_text,
       tr.tk AS _k, tr.d AS _d, tr.n AS _n, ct.o AS _o
FROM _sub_llm s
JOIN _calls c USING (ck)
JOIN _traces tr ON tr.tk = c.tk
JOIN _times ct ON ct.item = s.ck
JOIN _sub_times st ON st.item = s.sk
UNION ALL BY NAME
SELECT tr.trace_id, hex_id('span|' || sc.sk || '|tool', 16) AS span_id, hex_id('span|' || sc.ck || '|agent', 16) AS parent_span_id,
       tr.session_id, tr.tenant_id, tr.user_id, tr.environment, tr.app_release, 'execute_tool ' || sc.tool_name AS span_name, sc.kind,
       'explorer' AS agent_name, sc.tool_name, sc.tool_call_id,
       at_ms(tr.trace_start, ct.offset_ms + st.offset_ms) AS start_time, at_ms(tr.trace_start, ct.offset_ms + st.offset_ms + st.ms) AS end_time,
       round(st.ms)::BIGINT AS duration_ms, 'OK' AS status,
       tool_attributes(tr, sc.tool_call_id)::VARCHAR AS attributes, sc.input_text, sc.output_text,
       tr.tk AS _k, tr.d AS _d, tr.n AS _n, ct.o AS _o
FROM _sub_calls sc
JOIN _calls c USING (ck)
JOIN _traces tr ON tr.tk = c.tk
JOIN _times ct ON ct.item = sc.ck
JOIN _sub_times st ON st.item = sc.sk || '|tool';

-- Cost of model calls at the price of the day; failed calls are not billed
UPDATE _spans s SET cost_usd = CASE WHEN s.status = 'OK' THEN round((
        (s.input_tokens - s.cache_read_tokens) * p.input_price + s.cache_read_tokens * p.cache_read_price
        + (s.output_tokens + s.reasoning_tokens) * p.output_price) / 1000000, 9) ELSE 0 END
FROM (SELECT s.span_id, p.input_price, p.cache_read_price, p.output_price
      FROM _spans s ASOF JOIN _prices p ON s.model = p.model AND s.start_time >= p.valid_from
      WHERE s.kind = 'llm') p
WHERE s.span_id = p.span_id;
