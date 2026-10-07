/* TPC-H Q20 */
SELECT
    s_name,
    s_address
FROM
    tpch_sf1000.supplier,
    tpch_sf1000.nation
WHERE
    s_suppkey IN (
        SELECT
            ps_suppkey
        FROM
            tpch_sf1000.partsupp
        WHERE
            ps_partkey IN (
                SELECT
                    p_partkey
                FROM
                    tpch_sf1000.part
                WHERE
                    p_name LIKE 'forest%')
                AND ps_availqty > (
                    SELECT
                        0.5 * sum(l_quantity)
                    FROM
                        tpch_sf1000.lineitem
                    WHERE
                        l_partkey = ps_partkey
                        AND l_suppkey = ps_suppkey
                        AND l_shipdate >= CAST('1994-01-01' AS date)
                        AND l_shipdate < CAST('1995-01-01' AS date)))
            AND s_nationkey = n_nationkey
            AND n_name = 'CANADA'
        ORDER BY
            s_name;
