CREATE OR REPLACE TEMP TABLE _bucket AS
SELECT * FROM read_parquet('%%DIR%%/*.parquet', hive_partitioning = false);
