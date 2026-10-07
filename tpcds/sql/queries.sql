INSTALL tpcds;
LOAD tpcds;

SELECT printf('q%02d', query_nr) AS name, 'TPC-DS Q' || query_nr AS title, query
FROM tpcds_queries()
ORDER BY query_nr;
