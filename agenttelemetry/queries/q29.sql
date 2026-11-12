/* Agent Telemetry Q29: log tail, the newest 50 failed spans of one tenant's production runs, last 7 days */
SELECT start_time, trace_id, span_id, span_name, kind, error_type, duration_ms
FROM %%NAMESPACE%%.spans
WHERE tenant_id = 1 AND environment = 'prod' AND status = 'ERROR'
  AND start_time >= TIMESTAMPTZ '2025-12-25 00:00:00+00' AND start_time < TIMESTAMPTZ '2026-01-01 00:00:00+00'
ORDER BY start_time DESC, span_id
LIMIT 50
