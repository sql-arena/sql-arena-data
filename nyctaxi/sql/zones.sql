CREATE OR REPLACE TEMP TABLE part AS
SELECT CAST(LocationID AS INTEGER) AS location_id, Borough AS borough, Zone AS zone, service_zone
FROM read_csv('%%PATH%%', header = true)
ORDER BY location_id;
