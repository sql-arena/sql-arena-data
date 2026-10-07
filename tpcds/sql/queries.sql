INSTALL tpcds;
LOAD tpcds;

-- tpcds_queries() has SF1 parameters. Q9's five thresholds are drawn from 1 to rowcount("store_sales") / 5,
-- so they are scaled by the scale factor to keep each CASE branch as selective as at SF1.
SELECT printf('q%02d', query_nr) AS name,
       'TPC-DS Q' || query_nr AS title,
       CASE WHEN query_nr = 9 THEN array_to_string(list_transform(string_split(query, ') > '), (part, i) ->
                CASE WHEN i = 1 THEN part
                     ELSE CAST(CAST(regexp_extract(part, '^\d+') AS BIGINT) * %%SF%% AS VARCHAR)
                          || regexp_replace(part, '^\d+', '') END), ') > ')
            ELSE query END AS query
FROM tpcds_queries()
ORDER BY query_nr;
