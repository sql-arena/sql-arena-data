-- duckgenerate_step.sql
-- Template: the shell script replaces %%SF%% before executing.

INSTALL tpch;
LOAD tpch;

INSTALL tpcds;
LOAD tpcds;

-- Generate data
DROP SCHEMA IF EXISTS tpch CASCADE;
CREATE SCHEMA IF NOT EXISTS tpch;
USE tpch;
CALL dbgen(sf = %%SF%%, children = %%CHILDREN%%, step = %%STEP%%, schema = 'tpch');

DROP SCHEMA IF EXISTS tpcds CASCADE;
CREATE SCHEMA IF NOT EXISTS tpcds;
USE tpcds;
CALL dsdgen(sf = %%SF%%, children = %%CHILDREN%%, step = %%STEP%%, schema = 'tpcds');

-- Export TPCH (CSV + Parquet)
COPY tpch.lineitem  TO 'tpch/sf%%SF%%/lineitem_%%STEP%%_%%CHILDREN%%.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.orders    TO 'tpch/sf%%SF%%/orders_%%STEP%%_%%CHILDREN%%.csv'    (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpch.partsupp  TO 'tpch/sf%%SF%%/partsupp_%%STEP%%_%%CHILDREN%%.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY tpch.lineitem  TO 'tpch/sf%%SF%%/lineitem_%%STEP%%_%%CHILDREN%%.parquet' (FORMAT PARQUET);
COPY tpch.orders    TO 'tpch/sf%%SF%%/orders_%%STEP%%_%%CHILDREN%%.parquet'   (FORMAT PARQUET);
COPY tpch.partsupp  TO 'tpch/sf%%SF%%/partsupp_%%STEP%%_%%CHILDREN%%.parquet' (FORMAT PARQUET);

-- Export TPCDS (CSV + Parquet)
COPY tpcds.catalog_returns   TO 'tpcds/sf%%SF%%/catalog_returns_%%STEP%%_%%CHILDREN%%.csv'   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.catalog_sales     TO 'tpcds/sf%%SF%%/catalog_sales_%%STEP%%_%%CHILDREN%%.csv'     (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.store_returns     TO 'tpcds/sf%%SF%%/store_returns_%%STEP%%_%%CHILDREN%%.csv'     (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.store_sales       TO 'tpcds/sf%%SF%%/store_sales_%%STEP%%_%%CHILDREN%%.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_returns       TO 'tpcds/sf%%SF%%/web_returns_%%STEP%%_%%CHILDREN%%.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY tpcds.web_sales         TO 'tpcds/sf%%SF%%/web_sales_%%STEP%%_%%CHILDREN%%.csv'         (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY tpcds.catalog_returns   TO 'tpcds/sf%%SF%%/catalog_returns_%%STEP%%_%%CHILDREN%%.parquet'   (FORMAT PARQUET);
COPY tpcds.catalog_sales     TO 'tpcds/sf%%SF%%/catalog_sales_%%STEP%%_%%CHILDREN%%.parquet'     (FORMAT PARQUET);
COPY tpcds.store_returns     TO 'tpcds/sf%%SF%%/store_returns_%%STEP%%_%%CHILDREN%%.parquet'     (FORMAT PARQUET);
COPY tpcds.store_sales       TO 'tpcds/sf%%SF%%/store_sales_%%STEP%%_%%CHILDREN%%.parquet'       (FORMAT PARQUET);
COPY tpcds.web_returns       TO 'tpcds/sf%%SF%%/web_returns_%%STEP%%_%%CHILDREN%%.parquet'       (FORMAT PARQUET);
COPY tpcds.web_sales         TO 'tpcds/sf%%SF%%/web_sales_%%STEP%%_%%CHILDREN%%.parquet'       (FORMAT PARQUET);
