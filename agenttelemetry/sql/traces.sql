-- Sessions of days %%FIRST_DAY%% to %%LAST_DAY%%. Session n of a day has the same attributes at every scale factor,
-- which only adds sessions.
CREATE OR REPLACE TEMP TABLE _sessions AS
WITH days AS (
    SELECT d, round(%%SF%% * sessions_on(d))::BIGINT AS sessions, extra_support(d) AS extra_support
    FROM range(%%FIRST_DAY%%, %%LAST_DAY%% + 1) t(d)
), sessions AS (
    SELECT d, n, n >= sessions AS black_friday, 's|' || d || '|' || n AS k
    FROM (SELECT d, sessions, unnest(range(round(sessions * (1 + extra_support))::BIGINT)) AS n FROM days)
), tenants AS (
    SELECT d, n, k, black_friday, bucket(getvariable('tenant_cdf'), rnd('tenant|' || k)) AS drawn FROM sessions
)
SELECT s.d, s.n, s.k,
       md5('session|' || s.k) AS session_id,
       t.tenant_id, t.tier, t.region,
       'user_' || t.tenant_id || '_' || pick('user|' || s.k, t.users) AS user_id,
       CASE WHEN s.black_friday THEN 'support-agent'
            WHEN rnd('main|' || s.k) < 0.7 THEN t.main_agent
            ELSE getvariable('agent_names')[bucket(getvariable('agent_cdf'), rnd('agent|' || s.k))] END AS agent_name,
       CASE WHEN rnd('env|' || s.k) < 0.85 THEN 'prod' WHEN rnd('env|' || s.k) < 0.95 THEN 'staging' ELSE 'dev' END AS environment,
       day_start(s.d) + to_seconds(((bucket(getvariable('hour_cdf'), rnd('hour|' || s.k)) - 1) * 3600
                                    + floor(rnd('second|' || s.k) * 3600))::BIGINT) AS starts,
       least(8, 1 + floor(-ln(1 - rnd('traces|' || s.k)) * 1.2))::INTEGER AS traces,
       rnd('model|' || s.k) AS model_draw,
       CASE WHEN s.d >= 243 AND rnd('experiment|' || s.k) < 0.1 THEN 'ctx-compression-b' END AS experiment,
       CASE WHEN rnd('flags|' || s.k) < 0.2 THEN ['streaming-v2', 'compact-context', 'parallel-tools'][1:pick('nflags|' || s.k, 3)] END AS feature_flags
FROM tenants s
-- Before a tenant signs up its sessions go to one of the 18 tenants that exist all year
JOIN _tenants t ON t.tenant_id = CASE WHEN (SELECT created_day FROM _tenants WHERE tenant_id = s.drawn) > s.d
                                      THEN [1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20][pick('remap|' || s.k, 18)]
                                      ELSE s.drawn END;

-- A session's model: one of the models available that day, a new one ramping up over six weeks
CREATE OR REPLACE TEMP TABLE _session_models AS
WITH weights AS (
    SELECT s.k, m.model, m.provider,
           m.weight * least(1.0, (s.d - coalesce(m.released_day, -42)) / 42) AS w, s.model_draw
    FROM _sessions s, _models m
    WHERE s.d >= coalesce(m.released_day, -1) AND s.d < coalesce(m.retired_day, 9999)
), cumulative AS (
    SELECT *, sum(w) OVER (PARTITION BY k ORDER BY model ROWS UNBOUNDED PRECEDING) / sum(w) OVER (PARTITION BY k) AS c FROM weights
)
SELECT k, arg_min(model, c) AS model, arg_min(provider, c) AS provider FROM cumulative WHERE c > model_draw GROUP BY k;

-- Traces: the user's turns in a session, a few minutes apart
CREATE OR REPLACE TEMP TABLE _traces AS
SELECT s.*, m.model, m.provider, t.i, s.k || '|' || t.i AS tk,
       md5('trace|' || s.k || '|' || t.i) AS trace_id,
       s.starts + to_milliseconds((t.i * 420000 + floor(rnd('gap|' || s.k || '|' || t.i) * 300000))::BIGINT) AS trace_start,
       app_release(s.d, s.environment) AS app_release,
       -- Agent runs: turns of the model, and a sub-agent that some agents start from one tool call
       least(25, 1 + floor(-ln(1 - rnd('turns|' || s.k || '|' || t.i)) * (a.mean_turns - 1)))::INTEGER AS turns,
       rnd('subagent|' || s.k || '|' || t.i) < a.subagent_share AS has_subagent,
       a.tools AS agent_tools, a.tool_definition_tokens,
       -- Each agent gets a new system prompt every 75 days, on different days
       1 + (s.d + 30 * (a.share * 10)::INTEGER) // 75 AS prompt_version,
       rnd('quality|' || s.k || '|' || t.i) AS quality
FROM _sessions s
JOIN _session_models m USING (k)
JOIN _agents a USING (agent_name)
CROSS JOIN LATERAL (SELECT unnest(range(s.traces)) AS i) t;
