INSTALL tpch;
LOAD tpch;

DROP SCHEMA IF EXISTS tpch CASCADE;
CREATE SCHEMA tpch;
CALL dbgen(sf = %%SF%%, children = %%CHILDREN%%, step = %%STEP%%, schema = 'tpch');
