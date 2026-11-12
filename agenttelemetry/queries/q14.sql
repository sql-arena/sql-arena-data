/* Agent Telemetry Q14: spans and cost by region and tier from the VARIANT attributes, one day */
SELECT attributes."deployment.region"::VARCHAR AS region,
       attributes."customer.tier"::VARCHAR AS tier,
       count(*) AS spans, sum(cost_usd) AS cost_usd
FROM %%NAMESPACE%%.spans
WHERE start_time >= TIMESTAMPTZ '2025-12-15 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-12-16 00:00:00+00'
GROUP BY region, tier
ORDER BY region, tier
