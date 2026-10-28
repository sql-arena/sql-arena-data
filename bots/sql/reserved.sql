-- Words that cannot be a column name without quotes: DuckDB's and Postgres' reserved keywords, and the
-- SQL standard's USER functions, which Postgres reads as a call
SELECT keyword_name FROM duckdb_keywords() WHERE keyword_category IN ('reserved', 'type_function')
UNION SELECT unnest(['user', 'current_user', 'session_user', 'system_user']);
