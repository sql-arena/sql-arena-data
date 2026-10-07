/* TPC-H Q18 */
SELECT
    c_name,
    c_custkey,
    o_orderkey,
    o_orderdate,
    o_totalprice,
    sum(l_quantity)
FROM
    tpch_sf1.customer,
    tpch_sf1.orders,
    tpch_sf1.lineitem
WHERE
    o_orderkey IN (
        SELECT
            l_orderkey
        FROM
            tpch_sf1.lineitem
        GROUP BY
            l_orderkey
        HAVING
            sum(l_quantity) > 300)
    AND c_custkey = o_custkey
    AND o_orderkey = l_orderkey
GROUP BY
    c_name,
    c_custkey,
    o_orderkey,
    o_orderdate,
    o_totalprice
ORDER BY
    o_totalprice DESC,
    o_orderdate
LIMIT 100;
