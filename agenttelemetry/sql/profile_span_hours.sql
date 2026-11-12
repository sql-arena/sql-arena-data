CREATE OR REPLACE TABLE span_hours AS
SELECT date_trunc('hour', start_time) AS hour, count(*) AS spans
FROM %%NS%%.spans
GROUP BY hour
