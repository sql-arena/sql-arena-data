SELECT workbook || '_' || query_nr AS name, 'Public BI ' || workbook || ' ' || query_nr AS title, content AS query
FROM read_text('%%DIR%%/*/queries/*.sql'),
     LATERAL (SELECT regexp_extract(filename, '([^/]+)/queries/([^/]+)\.sql$', 1) AS workbook,
                     CAST(regexp_extract(filename, '([^/]+)/queries/([^/]+)\.sql$', 2) AS INTEGER) AS query_nr)
ORDER BY workbook, query_nr;
