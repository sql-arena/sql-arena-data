-- The table definitions of DuckDB's tpcds extension; the data comes from the TPC-DS kit's dsdgen
INSTALL tpcds;
LOAD tpcds;

DROP SCHEMA IF EXISTS tpcds CASCADE;
CREATE SCHEMA tpcds;
CALL dsdgen(sf = 0, schema = 'tpcds');
