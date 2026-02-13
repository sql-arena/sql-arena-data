-- gen_tpch_tpcds.sql
-- Template: the shell script replaces %%SF%% before executing.

INSTALL tpch;
LOAD tpch;

INSTALL tpcds;
LOAD tpcds;

-- Generate data
CREATE SCHEMA IF NOT EXISTS tpch;
USE tpch;
CALL dbgen(sf = %%SF%%, schema = 'tpch');

CREATE SCHEMA IF NOT EXISTS tpcds;
USE tpcds;
CALL dsdgen(sf = %%SF%%, schema = 'tpcds');

-- Export TPCH (CSV + Parquet)
COPY tpch.customer  TO 'tpc-h/sf%%SF%%/customer.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.lineitem  TO 'tpc-h/sf%%SF%%/lineitem.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.nation    TO 'tpc-h/sf%%SF%%/nation.csv'    (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.orders    TO 'tpc-h/sf%%SF%%/orders.csv'    (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.part      TO 'tpc-h/sf%%SF%%/part.csv'      (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.partsupp  TO 'tpc-h/sf%%SF%%/partsupp.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.region    TO 'tpc-h/sf%%SF%%/region.csv'    (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.supplier  TO 'tpc-h/sf%%SF%%/supplier.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY tpch.customer  TO 'tpc-h/sf%%SF%%/customer.parquet' (FORMAT PARQUET);
COPY tpch.lineitem  TO 'tpc-h/sf%%SF%%/lineitem.parquet' (FORMAT PARQUET);
COPY tpch.nation    TO 'tpc-h/sf%%SF%%/nation.parquet'   (FORMAT PARQUET);
COPY tpch.orders    TO 'tpc-h/sf%%SF%%/orders.parquet'   (FORMAT PARQUET);
COPY tpch.part      TO 'tpc-h/sf%%SF%%/part.parquet'     (FORMAT PARQUET);
COPY tpch.partsupp  TO 'tpc-h/sf%%SF%%/partsupp.parquet' (FORMAT PARQUET);
COPY tpch.region    TO 'tpc-h/sf%%SF%%/region.parquet'   (FORMAT PARQUET);
COPY tpch.supplier  TO 'tpc-h/sf%%SF%%/supplier.parquet' (FORMAT PARQUET);

-- Export TPC-DS (CSV + Parquet)
COPY tpcds.call_center            TO 'tpc-ds/sf%%SF%%/call_center.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.catalog_page           TO 'tpc-ds/sf%%SF%%/catalog_page.csv'           (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.catalog_returns        TO 'tpc-ds/sf%%SF%%/catalog_returns.csv'        (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.catalog_sales          TO 'tpc-ds/sf%%SF%%/catalog_sales.csv'          (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.customer               TO 'tpc-ds/sf%%SF%%/customer.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.customer_address       TO 'tpc-ds/sf%%SF%%/customer_address.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.customer_demographics  TO 'tpc-ds/sf%%SF%%/customer_demographics.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.date_dim               TO 'tpc-ds/sf%%SF%%/date_dim.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.household_demographics TO 'tpc-ds/sf%%SF%%/household_demographics.csv' (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.income_band            TO 'tpc-ds/sf%%SF%%/income_band.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.inventory              TO 'tpc-ds/sf%%SF%%/inventory.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.item                   TO 'tpc-ds/sf%%SF%%/item.csv'                   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.promotion              TO 'tpc-ds/sf%%SF%%/promotion.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.reason                 TO 'tpc-ds/sf%%SF%%/reason.csv'                 (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.ship_mode              TO 'tpc-ds/sf%%SF%%/ship_mode.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.store                  TO 'tpc-ds/sf%%SF%%/store.csv'                  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.store_returns          TO 'tpc-ds/sf%%SF%%/store_returns.csv'          (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.store_sales            TO 'tpc-ds/sf%%SF%%/store_sales.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.time_dim               TO 'tpc-ds/sf%%SF%%/time_dim.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.warehouse              TO 'tpc-ds/sf%%SF%%/warehouse.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_page               TO 'tpc-ds/sf%%SF%%/web_page.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_returns            TO 'tpc-ds/sf%%SF%%/web_returns.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_sales              TO 'tpc-ds/sf%%SF%%/web_sales.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_site               TO 'tpc-ds/sf%%SF%%/web_site.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY tpcds.call_center            TO 'tpc-ds/sf%%SF%%/call_center.parquet'            (FORMAT PARQUET);
COPY tpcds.catalog_page           TO 'tpc-ds/sf%%SF%%/catalog_page.parquet'           (FORMAT PARQUET);
COPY tpcds.catalog_returns        TO 'tpc-ds/sf%%SF%%/catalog_returns.parquet'        (FORMAT PARQUET);
COPY tpcds.catalog_sales          TO 'tpc-ds/sf%%SF%%/catalog_sales.parquet'          (FORMAT PARQUET);
COPY tpcds.customer               TO 'tpc-ds/sf%%SF%%/customer.parquet'               (FORMAT PARQUET);
COPY tpcds.customer_address       TO 'tpc-ds/sf%%SF%%/customer_address.parquet'       (FORMAT PARQUET);
COPY tpcds.customer_demographics  TO 'tpc-ds/sf%%SF%%/customer_demographics.parquet'  (FORMAT PARQUET);
COPY tpcds.date_dim               TO 'tpc-ds/sf%%SF%%/date_dim.parquet'               (FORMAT PARQUET);
COPY tpcds.household_demographics TO 'tpc-ds/sf%%SF%%/household_demographics.parquet' (FORMAT PARQUET);
COPY tpcds.income_band            TO 'tpc-ds/sf%%SF%%/income_band.parquet'            (FORMAT PARQUET);
COPY tpcds.inventory              TO 'tpc-ds/sf%%SF%%/inventory.parquet'              (FORMAT PARQUET);
COPY tpcds.item                   TO 'tpc-ds/sf%%SF%%/item.parquet'                   (FORMAT PARQUET);
COPY tpcds.promotion              TO 'tpc-ds/sf%%SF%%/promotion.parquet'              (FORMAT PARQUET);
COPY tpcds.reason                 TO 'tpc-ds/sf%%SF%%/reason.parquet'                 (FORMAT PARQUET);
COPY tpcds.ship_mode              TO 'tpc-ds/sf%%SF%%/ship_mode.parquet'              (FORMAT PARQUET);
COPY tpcds.store                  TO 'tpc-ds/sf%%SF%%/store.parquet'                  (FORMAT PARQUET);
COPY tpcds.store_returns          TO 'tpc-ds/sf%%SF%%/store_returns.parquet'          (FORMAT PARQUET);
COPY tpcds.store_sales            TO 'tpc-ds/sf%%SF%%/store_sales.parquet'            (FORMAT PARQUET);
COPY tpcds.time_dim               TO 'tpc-ds/sf%%SF%%/time_dim.parquet'               (FORMAT PARQUET);
COPY tpcds.warehouse              TO 'tpc-ds/sf%%SF%%/warehouse.parquet'              (FORMAT PARQUET);
COPY tpcds.web_page               TO 'tpc-ds/sf%%SF%%/web_page.parquet'               (FORMAT PARQUET);
COPY tpcds.web_returns            TO 'tpc-ds/sf%%SF%%/web_returns.parquet'            (FORMAT PARQUET);
COPY tpcds.web_sales              TO 'tpc-ds/sf%%SF%%/web_sales.parquet'              (FORMAT PARQUET);
COPY tpcds.web_site               TO 'tpc-ds/sf%%SF%%/web_site.parquet'               (FORMAT PARQUET);
