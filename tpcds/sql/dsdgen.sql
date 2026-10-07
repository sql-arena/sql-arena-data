INSTALL tpcds;
LOAD tpcds;

DROP SCHEMA IF EXISTS tpcds CASCADE;
CREATE SCHEMA tpcds;
CALL dsdgen(sf = %%SF%%, schema = 'tpcds');
