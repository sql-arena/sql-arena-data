SELECT name FROM parquet_schema('%%PATH%%') WHERE coalesce(num_children, 0) = 0;
