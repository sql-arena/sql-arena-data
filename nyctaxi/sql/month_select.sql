-- _row numbers the month's rows in pickup order, so consecutive parts cover consecutive time ranges
SELECT * FROM (
    SELECT %%SEGMENT%% AS _segment, row_number() OVER (ORDER BY pickup_datetime, file_row_number) - 1 AS _row, *
        EXCLUDE (file_row_number)
    FROM (SELECT file_row_number, %%COLUMNS%% FROM read_parquet('%%PATH%%', file_row_number = true))
)
WHERE _row >= %%START%% AND _row < %%END%%
