/* Agent Telemetry Q24: sessions of the last 7 days, runs per session, user think time and context growth by agent */
WITH runs AS (
    SELECT session_id, agent_name, start_time, input_tokens,
           epoch_ms(start_time) - lag(epoch_ms(end_time)) OVER (PARTITION BY session_id ORDER BY start_time) AS think_ms,
           row_number() OVER (PARTITION BY session_id ORDER BY start_time) AS run
    FROM agenttelemetry_sf1.traces
    WHERE start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
), sessions AS (
    SELECT session_id, agent_name, count(*) AS runs, avg(think_ms) AS think_ms,
           max(input_tokens) FILTER (WHERE run = 1) AS first_input_tokens, max(input_tokens) AS max_input_tokens
    FROM runs
    GROUP BY session_id, agent_name
)
SELECT agent_name, count(*) AS sessions, avg(runs) AS runs_per_session,
       quantile_cont(think_ms, 0.5) AS median_think_ms, avg(max_input_tokens * 1.0 / first_input_tokens) AS context_growth
FROM sessions
GROUP BY agent_name
ORDER BY agent_name
