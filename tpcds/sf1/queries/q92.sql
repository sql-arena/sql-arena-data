/* TPC-DS Q92 */
SELECT sum(ws_ext_discount_amt) AS "Excess Discount Amount"
FROM tpcds_sf1.web_sales,
     tpcds_sf1.item,
     tpcds_sf1.date_dim
WHERE i_manufact_id = 350
  AND i_item_sk = ws_item_sk
  AND d_date BETWEEN '2000-01-27' AND cast('2000-04-26' AS date)
  AND d_date_sk = ws_sold_date_sk
  AND ws_ext_discount_amt >
    (SELECT 1.3 * avg(ws_ext_discount_amt)
     FROM tpcds_sf1.web_sales,
          tpcds_sf1.date_dim
     WHERE ws_item_sk = i_item_sk
       AND d_date BETWEEN '2000-01-27' AND cast('2000-04-26' AS date)
       AND d_date_sk = ws_sold_date_sk )
ORDER BY sum(ws_ext_discount_amt)
LIMIT 100;
