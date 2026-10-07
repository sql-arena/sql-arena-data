INSTALL tpch;
LOAD tpch;

-- Q11's FRACTION is 0.0001 / SF in the TPC-H specification; tpch_queries() has the SF1 value
SELECT printf('q%02d', query_nr) AS name,
       'TPC-H Q' || query_nr AS title,
       replace(query, '0.0001000000', printf('%.10f', 0.0001 / %%SF%%)) AS query
FROM tpch_queries()
ORDER BY query_nr;
