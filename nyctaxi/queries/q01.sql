/* NYC Taxi Q01: trips and revenue per service */
SELECT 'yellow' AS service, COUNT(*) AS trips, SUM(total_amount) AS revenue
FROM nyctaxi.yellow_tripdata
UNION ALL
SELECT 'yellow_legacy', COUNT(*), SUM(total_amount)
FROM nyctaxi.yellow_tripdata_legacy
UNION ALL
SELECT 'green', COUNT(*), SUM(total_amount)
FROM nyctaxi.green_tripdata
UNION ALL
SELECT 'fhv', COUNT(*), NULL
FROM nyctaxi.fhv_tripdata
UNION ALL
SELECT 'fhvhv', COUNT(*), SUM(base_passenger_fare)
FROM nyctaxi.fhvhv_tripdata
ORDER BY service;
