INSTALL tpch;
LOAD tpch;

DROP SCHEMA IF EXISTS tpch CASCADE;
CREATE SCHEMA tpch;
CALL dbgen(sf = %%SF%%, schema = 'tpch');
