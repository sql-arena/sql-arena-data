-- One row per rejected line; a line can fail with several errors
SELECT s.file_path, e.line, string_agg(e.error_message, '; ')
FROM _rejects e JOIN _reject_scans s USING (scan_id, file_id)
GROUP BY ALL
ORDER BY ALL;
