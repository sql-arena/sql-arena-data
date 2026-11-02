/* Agent Telemetry Q05: time to first token and output speed by model, last 7 days */
SELECT model, count(*) AS calls,
       quantile_cont(epoch_ms(first_token_time) - epoch_ms(start_time), 0.5) AS p50_ttft_ms,
       quantile_cont(epoch_ms(first_token_time) - epoch_ms(start_time), 0.95) AS p95_ttft_ms,
       avg(output_tokens * 1000.0 / nullif(epoch_ms(end_time) - epoch_ms(first_token_time), 0)) AS output_tokens_per_second
FROM agenttelemetry_sf1.spans
WHERE kind = 'llm' AND status = 'OK'
  AND start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
GROUP BY model
ORDER BY model
