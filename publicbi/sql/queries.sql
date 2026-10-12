-- Renames the MonetDB functions DuckDB lacks: locate(needle, haystack) to strpos(haystack, needle), splitpart to split_part
SELECT workbook || '_' || query_nr AS name, 'Public BI ' || workbook || ' ' || query_nr AS title,
       regexp_replace(regexp_replace(content, 'locate\(''([^'']*)'',("[^"]+"\."[^"]+")\)', 'strpos(\2, ''\1'')', 'g'),
                      'splitpart\(', 'split_part(', 'g') AS query
FROM read_text('%%DIR%%/*/queries/*.sql'),
     LATERAL (SELECT regexp_extract(filename, '([^/]+)/queries/([^/]+)\.sql$', 1) AS workbook,
                     CAST(regexp_extract(filename, '([^/]+)/queries/([^/]+)\.sql$', 2) AS INTEGER) AS query_nr)
ORDER BY workbook, query_nr;
