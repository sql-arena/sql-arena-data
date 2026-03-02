-- duckgenerate_base.sql
-- Template: the shell script replaces %%SF%% before executing.

INSTALL tpch;
LOAD tpch;

INSTALL tpcds;
LOAD tpcds;

-- Generate data
DROP SCHEMA IF EXISTS tpch CASCADE;
CREATE SCHEMA IF NOT EXISTS tpch;
USE tpch;
CALL dbgen(sf = %%SF%%, schema = 'tpch');

DROP SCHEMA IF EXISTS tpcds CASCADE;
CREATE SCHEMA IF NOT EXISTS tpcds;
USE tpcds;
CALL dsdgen(sf = %%SF%%, schema = 'tpcds');

-- Export TPCH (CSV + Parquet)
COPY tpch.customer TO 'tpch/sf%%SF%%/customer.csv' (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.nation   TO 'tpch/sf%%SF%%/nation.csv'   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.part     TO 'tpch/sf%%SF%%/part.csv'     (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.region   TO 'tpch/sf%%SF%%/region.csv'   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.supplier TO 'tpch/sf%%SF%%/supplier.csv' (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY tpch.customer TO 'tpch/sf%%SF%%/customer.parquet' (FORMAT PARQUET);
COPY tpch.nation   TO 'tpch/sf%%SF%%/nation.parquet'   (FORMAT PARQUET);
COPY tpch.part     TO 'tpch/sf%%SF%%/part.parquet'     (FORMAT PARQUET);
COPY tpch.region   TO 'tpch/sf%%SF%%/region.parquet'   (FORMAT PARQUET);
COPY tpch.supplier TO 'tpch/sf%%SF%%/supplier.parquet' (FORMAT PARQUET);

-- Export TPCDS (CSV + Parquet)
COPY tpcds.call_center            TO 'tpcds/sf%%SF%%/call_center.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.catalog_page           TO 'tpcds/sf%%SF%%/catalog_page.csv'           (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.customer               TO 'tpcds/sf%%SF%%/customer.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.customer_address       TO 'tpcds/sf%%SF%%/customer_address.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.customer_demographics  TO 'tpcds/sf%%SF%%/customer_demographics.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.date_dim               TO 'tpcds/sf%%SF%%/date_dim.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.household_demographics TO 'tpcds/sf%%SF%%/household_demographics.csv' (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.income_band            TO 'tpcds/sf%%SF%%/income_band.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.inventory              TO 'tpcds/sf%%SF%%/inventory.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.item                   TO 'tpcds/sf%%SF%%/item.csv'                   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.promotion              TO 'tpcds/sf%%SF%%/promotion.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.reason                 TO 'tpcds/sf%%SF%%/reason.csv'                 (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.ship_mode              TO 'tpcds/sf%%SF%%/ship_mode.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.store                  TO 'tpcds/sf%%SF%%/store.csv'                  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.time_dim               TO 'tpcds/sf%%SF%%/time_dim.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.warehouse              TO 'tpcds/sf%%SF%%/warehouse.csv'              (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_page               TO 'tpcds/sf%%SF%%/web_page.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_site               TO 'tpcds/sf%%SF%%/web_site.csv'               (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY tpcds.call_center            TO 'tpcds/sf%%SF%%/call_center.parquet'            (FORMAT PARQUET);
COPY tpcds.catalog_page           TO 'tpcds/sf%%SF%%/catalog_page.parquet'           (FORMAT PARQUET);
COPY tpcds.customer               TO 'tpcds/sf%%SF%%/customer.parquet'               (FORMAT PARQUET);
COPY tpcds.customer_address       TO 'tpcds/sf%%SF%%/customer_address.parquet'       (FORMAT PARQUET);
COPY tpcds.customer_demographics  TO 'tpcds/sf%%SF%%/customer_demographics.parquet'  (FORMAT PARQUET);
COPY tpcds.date_dim               TO 'tpcds/sf%%SF%%/date_dim.parquet'               (FORMAT PARQUET);
COPY tpcds.household_demographics TO 'tpcds/sf%%SF%%/household_demographics.parquet' (FORMAT PARQUET);
COPY tpcds.income_band            TO 'tpcds/sf%%SF%%/income_band.parquet'            (FORMAT PARQUET);
COPY tpcds.inventory              TO 'tpcds/sf%%SF%%/inventory.parquet'              (FORMAT PARQUET);
COPY tpcds.item                   TO 'tpcds/sf%%SF%%/item.parquet'                   (FORMAT PARQUET);
COPY tpcds.promotion              TO 'tpcds/sf%%SF%%/promotion.parquet'              (FORMAT PARQUET);
COPY tpcds.reason                 TO 'tpcds/sf%%SF%%/reason.parquet'                 (FORMAT PARQUET);
COPY tpcds.ship_mode              TO 'tpcds/sf%%SF%%/ship_mode.parquet'              (FORMAT PARQUET);
COPY tpcds.store                  TO 'tpcds/sf%%SF%%/store.parquet'                  (FORMAT PARQUET);
COPY tpcds.time_dim               TO 'tpcds/sf%%SF%%/time_dim.parquet'               (FORMAT PARQUET);
COPY tpcds.warehouse              TO 'tpcds/sf%%SF%%/warehouse.parquet'              (FORMAT PARQUET);
COPY tpcds.web_page               TO 'tpcds/sf%%SF%%/web_page.parquet'               (FORMAT PARQUET);
COPY tpcds.web_site               TO 'tpcds/sf%%SF%%/web_site.parquet'               (FORMAT PARQUET);
