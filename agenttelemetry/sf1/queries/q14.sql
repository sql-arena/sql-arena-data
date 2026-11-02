/* Agent Telemetry Q14: spans and cost by region and tier from the JSON attributes, one day */
SELECT json_extract_string(attributes, '$."deployment.region"') AS region,
       json_extract_string(attributes, '$."customer.tier"') AS tier,
       count(*) AS spans, sum(cost_usd) AS cost_usd
FROM agenttelemetry_sf1.spans
WHERE start_time >= TIMESTAMPTZ '2025-12-15 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-12-16 00:00:00+00'
GROUP BY region, tier
ORDER BY region, tier
