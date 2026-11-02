-- Randomness is md5 of a salt and the row's key, so every run and scale factor gives the same data.
SET TimeZone = 'UTC';
CREATE OR REPLACE MACRO rnd(k) AS md5_number_lower(k)::DOUBLE / 18446744073709551616.0;
CREATE OR REPLACE MACRO pick(k, n) AS 1 + floor(rnd(k) * n)::BIGINT;
CREATE OR REPLACE MACRO hex_id(k, n) AS substr(md5(k), 1, n);
-- Index (1-based) of the bucket of a cumulative distribution that r falls in
CREATE OR REPLACE MACRO bucket(cdf, r) AS 1 + len(list_filter(cdf, c -> c <= r));
CREATE OR REPLACE MACRO day_start(d) AS (TIMESTAMP '%%FIRST_DATE%%' + to_days(d::INTEGER))::TIMESTAMPTZ;

-- Sessions on day d at SF 1: traffic grows threefold over the year and halves at weekends
CREATE OR REPLACE MACRO sessions_on(d) AS
    %%SESSIONS_PER_DAY%% * (0.5 + d / 364) * CASE WHEN isodow(day_start(d)) >= 6 THEN 0.45 ELSE 1.0 END;
-- Black Friday brings extra support sessions, as a share of the day's sessions
CREATE OR REPLACE MACRO extra_support(d) AS CASE WHEN day_start(d) = TIMESTAMPTZ '2025-11-28 00:00:00+00' THEN 1.5 ELSE 0 END;

SET VARIABLE hour_cdf = (
    SELECT list_transform(range(1, 25), i -> list_sum(%%HOUR_WEIGHTS%%[1:i]) / list_sum(%%HOUR_WEIGHTS%%))[1:23]
);

-- Production ships a release every two weeks; staging gets it a week earlier
CREATE OR REPLACE MACRO app_release(d, environment) AS
    'v2.' || (1 + (d + CASE environment WHEN 'prod' THEN 0 ELSE 7 END) // 14) || '.0'
    || CASE environment WHEN 'dev' THEN '-dev' ELSE '' END;

-- Words for the text pools
SET VARIABLE nouns = ['order', 'invoice', 'customer', 'session', 'token', 'cache', 'request', 'payload', 'schema',
    'index', 'cluster', 'shard', 'queue', 'worker', 'tenant', 'account', 'report', 'metric', 'alert', 'deployment',
    'migration', 'table', 'column', 'query', 'user', 'service', 'config', 'endpoint', 'record', 'batch', 'refund',
    'shipment', 'subscription', 'payment', 'ticket', 'price', 'product', 'warehouse', 'region', 'pipeline'];
SET VARIABLE verbs = ['load', 'parse', 'validate', 'fetch', 'update', 'merge', 'retry', 'deploy', 'sync', 'render',
    'encode', 'resolve', 'compute', 'filter', 'publish', 'archive', 'refresh', 'migrate', 'schedule', 'notify'];
CREATE OR REPLACE MACRO past(verb) AS regexp_replace(regexp_replace(verb || 'ed', 'eed$', 'ed'), 'yed$', 'ied');
SET VARIABLE adjectives = ['stale', 'pending', 'duplicate', 'missing', 'expired', 'partial', 'cached', 'invalid',
    'active', 'archived', 'primary', 'remote', 'nightly', 'legacy', 'regional', 'default'];
SET VARIABLE services = ['orders-api', 'billing', 'auth', 'search', 'inventory', 'gateway', 'scheduler', 'notifier'];
CREATE OR REPLACE MACRO word(list, k) AS list[pick(k, len(list))];
CREATE OR REPLACE MACRO cap(s) AS upper(s[1]) || s[2:];

-- Text pools: a span's text is a run of consecutive lines of one pool, so it costs one hash
CREATE OR REPLACE TEMP TABLE _pools AS
WITH lines AS (
    SELECT 'code' AS pool, i, CASE i % 9
        WHEN 0 THEN 'def ' || word(getvariable('verbs'), 'c1|' || i) || '_' || word(getvariable('nouns'), 'c2|' || i)
                    || '(' || word(getvariable('nouns'), 'c3|' || i) || '_id, limit=' || pick('c4|' || i, 500) || '):'
        WHEN 1 THEN '    """' || cap(word(getvariable('verbs'), 'c5|' || i)) || ' the '
                    || word(getvariable('adjectives'), 'c6|' || i) || ' ' || word(getvariable('nouns'), 'c7|' || i) || 's."""'
        WHEN 2 THEN '    ' || word(getvariable('nouns'), 'c8|' || i) || ' = ' || word(getvariable('verbs'), 'c9|' || i)
                    || '_' || word(getvariable('nouns'), 'c10|' || i) || '(' || word(getvariable('nouns'), 'c11|' || i) || ')'
        WHEN 3 THEN '    if ' || word(getvariable('nouns'), 'c12|' || i) || ' is None:'
        WHEN 4 THEN '        raise ValueError("' || word(getvariable('nouns'), 'c13|' || i) || ' not found")'
        WHEN 5 THEN '    for ' || word(getvariable('nouns'), 'c14|' || i) || ' in self.'
                    || word(getvariable('nouns'), 'c15|' || i) || 's:'
        WHEN 6 THEN '        self.' || word(getvariable('verbs'), 'c16|' || i) || '(' || word(getvariable('nouns'), 'c17|' || i)
                    || ', retries=' || pick('c18|' || i, 5) || ')'
        WHEN 7 THEN '    # TODO: ' || word(getvariable('verbs'), 'c19|' || i) || ' ' || word(getvariable('adjectives'), 'c20|' || i)
                    || ' ' || word(getvariable('nouns'), 'c21|' || i) || 's'
        ELSE '    return ' || word(getvariable('nouns'), 'c22|' || i)
        END AS line
    FROM range(5000) t(i)
    UNION ALL
    SELECT 'log', i, CASE
        WHEN rnd('l0|' || i) < 0.03 THEN 'ERROR [' || word(getvariable('services'), 'l1|' || i) || '] connection refused: '
             || word(getvariable('nouns'), 'l2|' || i) || '-db-' || pick('l3|' || i, 9) || ':5432'
        WHEN rnd('l0|' || i) < 0.06 THEN 'WARN  [' || word(getvariable('services'), 'l4|' || i) || '] request timed out after '
             || pick('l5|' || i, 30) || 's, retrying (attempt ' || pick('l6|' || i, 3) || ')'
        WHEN rnd('l0|' || i) < 0.08 THEN 'ERROR [' || word(getvariable('services'), 'l7|' || i) || '] Traceback (most recent call last): '
             || cap(word(getvariable('nouns'), 'l8|' || i)) || 'Error: ' || word(getvariable('adjectives'), 'l9|' || i) || ' '
             || word(getvariable('nouns'), 'l10|' || i)
        ELSE 'INFO  [' || word(getvariable('services'), 'l11|' || i) || '] ' || ['GET', 'GET', 'POST', 'PUT', 'DELETE'][pick('l12|' || i, 5)]
             || ' /v1/' || word(getvariable('nouns'), 'l13|' || i) || 's/' || pick('l14|' || i, 99999) || ' '
             || [200, 200, 200, 201, 204, 404, 500][pick('l15|' || i, 7)] || ' in ' || pick('l16|' || i, 900) || 'ms'
        END
    FROM range(5000) t(i)
    UNION ALL
    SELECT 'prose', i, 'The ' || word(getvariable('adjectives'), 'p1|' || i) || ' ' || word(getvariable('nouns'), 'p2|' || i) || ' '
        || ['is', 'was', 'should be', 'cannot be', 'will be'][pick('p3|' || i, 5)] || ' '
        || past(word(getvariable('verbs'), 'p4|' || i)) || ' ' || ['before', 'after', 'when', 'unless', 'because'][pick('p5|' || i, 5)]
        || ' the ' || word(getvariable('nouns'), 'p6|' || i) || ' ' || ['is', 'is not', 'has been', 'looks'][pick('p7|' || i, 4)] || ' '
        || word(getvariable('adjectives'), 'p8|' || i) || '.'
    FROM range(3000) t(i)
    UNION ALL
    SELECT 'path', i, ['src', 'lib', 'tests', 'services', 'api'][pick('f1|' || i, 5)] || '/'
        || word(getvariable('nouns'), 'f2|' || i) || 's/' || word(getvariable('verbs'), 'f3|' || i) || '_'
        || word(getvariable('nouns'), 'f4|' || i) || ['.py', '.py', '.ts', '.go', '.sql', '.yaml'][pick('f5|' || i, 6)]
    FROM range(600) t(i)
    UNION ALL
    SELECT 'url', i, cap(word(getvariable('adjectives'), 'u1|' || i)) || ' ' || word(getvariable('nouns'), 'u2|' || i)
        || ' handling in practice - https://' || ['docs', 'blog', 'wiki', 'forum'][pick('u3|' || i, 4)] || '.example.'
        || ['com', 'org', 'dev'][pick('u4|' || i, 3)] || '/' || word(getvariable('nouns'), 'u5|' || i) || '/'
        || word(getvariable('verbs'), 'u6|' || i) || '-' || pick('u7|' || i, 9999)
    FROM range(1500) t(i)
    UNION ALL
    SELECT 'rows', i, pick('r1|' || i, 999999) || ',' || word(getvariable('nouns'), 'r2|' || i) || ','
        || word(getvariable('adjectives'), 'r3|' || i) || ',' || round(rnd('r4|' || i) * 10000, 2) || ','
        || (DATE '2024-01-01' + pick('r5|' || i, 700)::INTEGER)
    FROM range(3000) t(i)
    UNION ALL
    SELECT 'sql', i, 'SELECT ' || word(getvariable('nouns'), 's1|' || i) || '_id, ' || ['count(*)', 'sum(amount)', 'avg(latency_ms)', 'max(updated_at)'][pick('s2|' || i, 4)]
        || ' FROM ' || ['sales', 'ops', 'billing', 'events'][pick('s3|' || i, 4)] || '.' || word(getvariable('nouns'), 's4|' || i) || 's'
        || ' WHERE ' || ['created_at', 'event_date', 'updated_at'][pick('s5|' || i, 3)] || ' >= DATE ''2025-'
        || lpad(pick('s6|' || i, 12)::VARCHAR, 2, '0') || '-01'' GROUP BY 1 ORDER BY 2 DESC LIMIT ' || [10, 20, 50, 100][pick('s7|' || i, 4)]
    FROM range(400) t(i)
)
SELECT pool, list(line ORDER BY i) AS lines FROM lines GROUP BY pool;

CREATE OR REPLACE MACRO pool(name) AS (SELECT lines FROM _pools WHERE pool = name);
SET VARIABLE code = pool('code');
SET VARIABLE log = pool('log');
SET VARIABLE prose = pool('prose');
SET VARIABLE path = pool('path');
SET VARIABLE url = pool('url');
SET VARIABLE rows = pool('rows');
SET VARIABLE sql = pool('sql');
-- n consecutive lines of a pool from a random start
CREATE OR REPLACE MACRO run(lines, k, n) AS
    array_to_string(lines[pick(k, len(lines) - n) : pick(k, len(lines) - n) + n - 1], chr(10));

CREATE OR REPLACE MACRO pool_run(name, k, n) AS CASE name
    WHEN 'code' THEN run(getvariable('code'), k, n) WHEN 'log' THEN run(getvariable('log'), k, n)
    WHEN 'prose' THEN run(getvariable('prose'), k, n) WHEN 'path' THEN run(getvariable('path'), k, n)
    WHEN 'url' THEN run(getvariable('url'), k, n) WHEN 'rows' THEN run(getvariable('rows'), k, n) END;

-- Tenants: Zipf distributed traffic; the first 20 exist before the year starts and the others sign up during it,
-- two of the large ones among them
CREATE OR REPLACE TEMP TABLE _tenants AS
WITH t AS (
    SELECT k AS tenant_id, 1 / pow(k, 1.1) AS weight,
           CASE WHEN k = 3 THEN 201 WHEN k = 7 THEN 278 WHEN k <= 20 THEN NULL
                ELSE 10 + floor(rnd('created|' || k) * 340)::INTEGER END AS created_day
    FROM range(1, %%TENANTS%% + 1) r(k)
)
SELECT tenant_id, 'org_' || lpad(tenant_id::VARCHAR, 3, '0') AS name,
       CASE WHEN tenant_id <= 10 THEN 'enterprise' WHEN tenant_id <= 60 THEN 'team' ELSE 'free' END AS tier,
       ['us-east-1', 'us-east-1', 'eu-west-1', 'eu-west-1', 'ap-southeast-2'][pick('region|' || tenant_id, 5)] AS region,
       CASE WHEN created_day IS NULL THEN TIMESTAMPTZ '%%FIRST_DATE%%' - to_days(pick('founded|' || tenant_id, 700)::INTEGER)
            ELSE day_start(created_day) + to_seconds(pick('signup|' || tenant_id, 86000)) END AS created_at,
       coalesce(created_day, -1) AS created_day,
       weight / sum(weight) OVER () AS share,
       sum(weight) OVER (ORDER BY tenant_id) / sum(weight) OVER () AS cdf,
       ['coding-agent', 'support-agent', 'research-agent', 'data-agent', 'sre-agent'][1 + tenant_id % 5] AS main_agent,
       5 + round(weight / sum(weight) OVER () * %%USERS%%)::BIGINT AS users
FROM t;
SET VARIABLE tenant_cdf = (SELECT list(cdf ORDER BY tenant_id)[1:-2] FROM _tenants);

-- Agents: their tools, system prompt size and how many turns a run takes
CREATE OR REPLACE TEMP TABLE _agents AS
SELECT * FROM (VALUES
    ('coding-agent', 0.40, ['read_file', 'read_file', 'edit_file', 'bash', 'grep', 'glob', 'web_fetch'], 7.0, 0.35, 9000),
    ('support-agent', 0.25, ['search_kb', 'get_ticket', 'update_ticket', 'lookup_order', 'send_email'], 3.0, 0.0, 2500),
    ('research-agent', 0.15, ['web_search', 'web_search', 'web_fetch', 'read_pdf'], 5.0, 0.30, 3500),
    ('data-agent', 0.12, ['list_tables', 'describe_table', 'sql_query', 'sql_query', 'run_python'], 4.0, 0.0, 4500),
    ('sre-agent', 0.08, ['query_logs', 'get_metrics', 'kubectl', 'bash', 'page_oncall'], 4.0, 0.0, 5000)
) a(agent_name, share, tools, mean_turns, subagent_share, tool_definition_tokens);
SET VARIABLE agent_cdf = (SELECT list(c ORDER BY i)[1:-2] FROM (
    SELECT row_number() OVER () AS i, sum(share) OVER (ROWS UNBOUNDED PRECEDING) AS c FROM _agents));
SET VARIABLE agent_names = (SELECT list(agent_name) FROM _agents);

-- Models: released and retired during the year; a new model takes six weeks to reach its full share
CREATE OR REPLACE TEMP TABLE _models AS
SELECT * FROM (VALUES
    ('acme-large-1', 'acme', NULL, 181, 3.0, 200000, 45, false, 'acme-small-1'),
    ('acme-large-2', 'acme', 134, NULL, 4.0, 200000, 60, false, 'acme-small-1'),
    ('acme-small-1', 'acme', NULL, NULL, 2.0, 200000, 120, false, 'acme-small-1'),
    ('globex-pro', 'globex', NULL, NULL, 2.5, 128000, 55, false, 'globex-flash'),
    ('globex-flash', 'globex', 59, NULL, 1.5, 24000, 150, false, 'globex-flash'),
    ('globex-pro-2', 'globex', 292, NULL, 4.0, 256000, 70, true, 'globex-flash'),
    ('initech-reasoner', 'initech', 40, NULL, 1.0, 128000, 35, true, 'initech-reasoner')
) m(model, provider, released_day, retired_day, weight, context_tokens, tokens_per_second, reasoning, small_model);

-- Prices in USD per million tokens, with the changes during the year
CREATE OR REPLACE TEMP TABLE _prices AS
SELECT provider, model, valid_from::TIMESTAMPTZ AS valid_from,
       input_price::DECIMAL(12, 6) AS input_price, output_price::DECIMAL(12, 6) AS output_price,
       cache_read_price::DECIMAL(12, 6) AS cache_read_price
FROM (VALUES
    ('acme', 'acme-large-1', TIMESTAMP '2024-06-01', 15.0, 75.0, 1.5),
    ('acme', 'acme-large-2', TIMESTAMP '2025-05-15', 3.0, 15.0, 0.3),
    ('acme', 'acme-large-2', TIMESTAMP '2025-11-01', 2.5, 12.5, 0.25),
    ('acme', 'acme-small-1', TIMESTAMP '2024-03-01', 0.8, 4.0, 0.08),
    ('globex', 'globex-pro', TIMESTAMP '2024-09-01', 10.0, 30.0, 2.5),
    ('globex', 'globex-pro', TIMESTAMP '2025-08-01', 5.0, 15.0, 1.25),
    ('globex', 'globex-flash', TIMESTAMP '2025-03-01', 0.3, 1.2, 0.075),
    ('globex', 'globex-pro-2', TIMESTAMP '2025-10-20', 6.0, 24.0, 1.5),
    ('initech', 'initech-reasoner', TIMESTAMP '2025-02-10', 2.0, 8.0, 0.5),
    ('initech', 'initech-reasoner', TIMESTAMP '2025-07-01', 1.1, 4.4, 0.275)
) p(provider, model, valid_from, input_price, output_price, cache_read_price);

-- Tools: kind, the pool and line count of their output, median latency, and how often and how they fail
CREATE OR REPLACE TEMP TABLE _tools AS
SELECT * FROM (VALUES
    ('read_file', 'tool', 'code', 20, 150, 15, 0.02, 'file_not_found', 'ENOENT: no such file or directory'),
    ('edit_file', 'tool', NULL, 0, 0, 30, 0.03, 'patch_failed', 'Edit failed: old_string not found in file'),
    ('bash', 'tool', 'log', 3, 60, 2500, 0.08, 'exit_code', 'Command failed with exit code 1'),
    ('grep', 'tool', 'path', 2, 40, 120, 0.01, 'timeout', 'grep timed out after 30s'),
    ('glob', 'tool', 'path', 2, 50, 40, 0.005, 'timeout', 'glob timed out after 30s'),
    ('web_fetch', 'tool', 'prose', 10, 80, 1800, 0.05, 'http_error', 'HTTP 403 Forbidden'),
    ('web_search', 'retrieval', 'url', 5, 10, 900, 0.02, 'timeout', 'Search provider timed out'),
    ('read_pdf', 'tool', 'prose', 30, 150, 3500, 0.03, 'parse_error', 'Could not extract text from PDF'),
    ('search_kb', 'retrieval', 'prose', 5, 20, 250, 0.01, 'timeout', 'Knowledge base search timed out'),
    ('get_ticket', 'tool', 'prose', 3, 10, 120, 0.01, 'not_found', 'Ticket not found'),
    ('update_ticket', 'tool', NULL, 0, 0, 150, 0.02, 'conflict', 'Ticket was modified by another user'),
    ('lookup_order', 'tool', 'rows', 1, 5, 90, 0.03, 'not_found', 'Order not found'),
    ('send_email', 'tool', NULL, 0, 0, 400, 0.01, 'smtp_error', 'SMTP 451: temporary failure'),
    ('list_tables', 'tool', 'path', 5, 40, 200, 0.005, 'permission_denied', 'permission denied for schema'),
    ('describe_table', 'tool', 'rows', 5, 30, 150, 0.01, 'not_found', 'Catalog Error: table does not exist'),
    ('sql_query', 'tool', 'rows', 1, 200, 1500, 0.07, 'sql_error', 'Binder Error: Referenced column not found'),
    ('run_python', 'tool', 'log', 2, 40, 3000, 0.06, 'exception', 'Traceback (most recent call last): KeyError'),
    ('query_logs', 'tool', 'log', 10, 100, 2000, 0.03, 'timeout', 'Log query timed out after 60s'),
    ('get_metrics', 'tool', 'rows', 10, 60, 600, 0.02, 'timeout', 'Metrics backend timed out'),
    ('kubectl', 'tool', 'log', 3, 30, 800, 0.04, 'exit_code', 'error: You must be logged in to the server'),
    ('page_oncall', 'tool', NULL, 0, 0, 300, 0.0, NULL, NULL),
    ('task', 'tool', 'prose', 3, 12, 0, 0.0, NULL, NULL)
) t(tool_name, kind, pool, min_lines, max_lines, median_ms, error_rate, error_type, error_message);

-- Incidents: windows in which a provider or tool fails more often or is slower
CREATE OR REPLACE TEMP TABLE _incidents AS
SELECT * FROM (VALUES
    (TIMESTAMPTZ '2025-03-18 13:00:00+00', TIMESTAMPTZ '2025-03-18 16:30:00+00', 'globex', NULL, 'overloaded_error', 0.35, 1.0),
    (TIMESTAMPTZ '2025-07-09 00:00:00+00', TIMESTAMPTZ '2025-07-10 00:00:00+00', NULL, 'web_search', 'timeout', 0.40, 6.0),
    (TIMESTAMPTZ '2025-09-02 14:00:00+00', TIMESTAMPTZ '2025-09-02 15:15:00+00', 'acme', NULL, 'rate_limit_error', 0.50, 1.0)
) i(starts, ends, provider, tool_name, error_type, error_rate, latency_factor);
-- A regression shipped in one release
SET VARIABLE bad_release = 'v2.24.0';
