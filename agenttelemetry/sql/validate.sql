-- Measures that the validate step of agenttelemetry/s3tables.py compares with the claims of agenttelemetry/README.md
WITH sessions AS (
    SELECT session_id, any_value(agent_name) AS agent_name, any_value(tenant_id) AS tenant_id,
           min(start_time) AS start_time
    FROM %%NS%%.traces GROUP BY session_id
), span_times AS (
    SELECT start_time FROM %%NS%%.spans
), codes AS (
    SELECT code, count(*) AS spans
    FROM (SELECT unnest(regexp_extract_all(coalesce(input_text::VARCHAR, '') || chr(10) || coalesce(output_text::VARCHAR, ''), 'ERR_[0-9A-F]{12}')) AS code
          FROM %%NS%%.spans WHERE input_text LIKE '%ERR\_%' ESCAPE '\' OR output_text LIKE '%ERR\_%' ESCAPE '\')
    GROUP BY code
), places AS (
    SELECT place, count(*) AS spans, min(start_time)::DATE AS first_day
    FROM (SELECT regexp_extract(input_text::VARCHAR, 'The customer lives in ([^,.]+)', 1) AS place, start_time
          FROM %%NS%%.spans WHERE input_text LIKE '%The customer lives in %')
    GROUP BY place
)
SELECT 'rows spans' AS name, count(*)::DOUBLE AS actual FROM span_times
UNION ALL SELECT 'rows traces', count(*) FROM %%NS%%.traces
UNION ALL SELECT 'rows scores', count(*) FROM %%NS%%.scores
UNION ALL SELECT 'rows tenants', count(*) FROM %%NS%%.tenants
UNION ALL SELECT 'rows model_prices', count(*) FROM %%NS%%.model_prices
UNION ALL SELECT 'distinct traces.session_id', count(*) FROM sessions
UNION ALL SELECT 'distinct traces.user_id', count(DISTINCT user_id) FROM %%NS%%.traces
UNION ALL SELECT 'share of traces in tenant 1 %', 100 * avg((tenant_id = 1)::INT) FROM %%NS%%.traces
UNION ALL SELECT 'share of sessions ' || agent_name || ' %', 100 * count(*) / sum(count(*)) OVER () FROM sessions GROUP BY agent_name
UNION ALL SELECT 'share of spans in the last 7 days %', 100 * avg((start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00')::INT) FROM span_times
UNION ALL SELECT 'share of spans in the last quarter %', 100 * avg((start_time >= TIMESTAMPTZ '2025-10-01 00:00:00+00')::INT) FROM span_times
UNION ALL SELECT 'share of spans in Q16 hour %',
    100 * avg((start_time >= TIMESTAMPTZ '2025-12-31 15:00:00+00' AND start_time < TIMESTAMPTZ '2025-12-31 16:00:00+00')::INT) FROM span_times
UNION ALL SELECT 'support sessions on Black Friday', count(*) FROM sessions
    WHERE agent_name = 'support-agent' AND start_time >= TIMESTAMPTZ '2025-11-28 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-11-29 00:00:00+00'
UNION ALL SELECT 'support sessions the Friday before', count(*) FROM sessions
    WHERE agent_name = 'support-agent' AND start_time >= TIMESTAMPTZ '2025-11-21 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-11-22 00:00:00+00'
UNION ALL SELECT 'needle sessions 0-39 of each day found', count(*)
    FROM (SELECT needle_session(d, n) AS session_id FROM range(365) a(d), range(40) b(n)) JOIN sessions USING (session_id)
UNION ALL SELECT 'needle traces of sessions 0-39 found', count(*)
    FROM (SELECT needle_trace(d, n, 0) AS trace_id FROM range(365) a(d), range(40) b(n)) JOIN %%NS%%.traces USING (trace_id)
UNION ALL SELECT 'needle codes in exactly 2 spans', count(*)
    FROM (SELECT needle_code(d, k) AS code FROM range(365) a(d), range(4) b(k)) JOIN codes USING (code) WHERE spans = 2
UNION ALL SELECT 'needle places in exactly 2 spans on their day', count(*)
    FROM (SELECT needle_place(d) AS place, DATE '2025-01-01' + d::INTEGER AS first_day FROM range(365) a(d))
    JOIN places USING (place, first_day) WHERE spans = 2
UNION ALL SELECT 'other planted places', count(*) FROM places WHERE place <> 'Ærøskøbing'
    AND place NOT IN (SELECT needle_place(d) FROM range(365) a(d))
UNION ALL SELECT 'Q10 key rows', count(*) FROM %%NS%%.spans WHERE input_text LIKE '%sk_live_%' OR output_text LIKE '%sk_live_%'
UNION ALL SELECT 'Q11 ERR_LEDGER_SHARD_7731 rows', count(*) FROM %%NS%%.spans
    WHERE (input_text LIKE '%ERR_LEDGER_SHARD_7731%' OR output_text LIKE '%ERR_LEDGER_SHARD_7731%')
UNION ALL SELECT 'Q13 Ærøskøbing rows', count(*) FROM %%NS%%.spans WHERE input_text LIKE '%Ærøskøbing%'
ORDER BY name
