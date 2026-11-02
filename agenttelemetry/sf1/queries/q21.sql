/* Agent Telemetry Q21: release regression, tool error rate by release from the JSON attributes, November */
SELECT json_extract_string(attributes, '$."app.release"') AS release_version, tool_name, count(*) AS calls,
       avg(CASE WHEN status = 'ERROR' THEN 1.0 ELSE 0.0 END) AS error_rate
FROM agenttelemetry_sf1.spans
WHERE kind = 'tool' AND tool_name IN ('edit_file', 'bash', 'read_file')
  AND start_time >= TIMESTAMPTZ '2025-11-01 00:00:00+00' AND start_time < TIMESTAMPTZ '2025-12-01 00:00:00+00'
GROUP BY release_version, tool_name
HAVING count(*) >= 20
ORDER BY release_version, tool_name
