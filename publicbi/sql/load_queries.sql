CREATE OR REPLACE TABLE _queries AS
SELECT content AS query FROM read_text('%%DIR%%/*.sql');
