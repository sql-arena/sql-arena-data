/* Agent Telemetry Q11: needle in one week, the runs that saw error code ERR_LEDGER_SHARD_7731 */
SELECT CAST(start_time AS DATE) AS day, count(DISTINCT trace_id) AS runs, count(*) AS spans
FROM agenttelemetry_sf10.spans
WHERE (input_text LIKE '%ERR_LEDGER_SHARD_7731%' OR output_text LIKE '%ERR_LEDGER_SHARD_7731%')
  AND start_time >= TIMESTAMPTZ '2025-10-06 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-10-13 00:00:00+00'
GROUP BY day
ORDER BY day
