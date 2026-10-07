COPY (SELECT *, strftime(%%ORDER_BY%%, '%Y-%m') AS _month FROM tpch.%%TABLE%%)
TO '%%DIR%%' (FORMAT PARQUET, PARTITION_BY (_month), FILENAME_PATTERN 'step_%%STEP%%_{i}', OVERWRITE_OR_IGNORE);
