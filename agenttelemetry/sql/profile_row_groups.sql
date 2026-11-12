-- Per row group min/max statistics of every column of a table, to tell which row groups a filter can skip
CREATE TABLE IF NOT EXISTS row_groups (tbl VARCHAR, file VARCHAR, rg BIGINT, num_rows BIGINT, col VARCHAR,
                                       min VARCHAR, max VARCHAR);
INSERT INTO row_groups
SELECT '%%TABLE%%', file_name, row_group_id, row_group_num_rows, path_in_schema,
       coalesce(stats_min_value, stats_min), coalesce(stats_max_value, stats_max)
FROM parquet_metadata('%%ROOT%%/%%TABLE%%/*.parquet');
