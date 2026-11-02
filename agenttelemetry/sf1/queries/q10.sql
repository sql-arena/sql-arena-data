/* Agent Telemetry Q10: needle, a leaked live API key anywhere in the text of the whole year */
SELECT trace_id, span_id, span_name, start_time
FROM agenttelemetry_sf1.spans
WHERE input_text LIKE '%sk_live_%' OR output_text LIKE '%sk_live_%'
ORDER BY start_time, span_id
