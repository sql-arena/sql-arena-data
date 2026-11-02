/* Agent Telemetry Q25: cost recomputed from the price in force at each call, two weeks around a price change */
SELECT s.model, count(*) AS calls, sum(s.cost_usd) AS stored_cost_usd,
       sum(CAST(round(((s.input_tokens - s.cache_read_tokens) * p.input_price + s.cache_read_tokens * p.cache_read_price
                       + (s.output_tokens + s.reasoning_tokens) * p.output_price) / 1000000, 9) AS DECIMAL(18, 9))) AS priced_cost_usd
FROM agenttelemetry_sf10.spans s
ASOF JOIN agenttelemetry_sf10.model_prices p ON p.model = s.model AND s.start_time >= p.valid_from
WHERE s.kind = 'llm' AND s.status = 'OK'
  AND s.start_time >= TIMESTAMPTZ '2025-06-24 00:00:00+00' AND s.start_time < TIMESTAMPTZ '2025-07-08 00:00:00+00'
GROUP BY s.model
ORDER BY s.model
