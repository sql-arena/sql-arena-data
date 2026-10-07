CREATE OR REPLACE TEMP TABLE _month AS
SELECT * FROM read_parquet('%%DIR%%/*.parquet', hive_partitioning = false);
