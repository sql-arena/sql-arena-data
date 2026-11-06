/* Agent Telemetry Q26: weekly model mix over the whole year */
SELECT date_trunc('week', start_time) AS week, model, count(*) AS runs, sum(cost_usd) AS cost_usd
FROM agenttelemetry_sf1000.traces
GROUP BY week, model
ORDER BY week, model
