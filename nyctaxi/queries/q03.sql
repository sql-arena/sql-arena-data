/* NYC Taxi Q03: trips by passenger count and year */
SELECT passenger_count,
       EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
       COUNT(*) AS trips
FROM nyctaxi.yellow_tripdata
GROUP BY passenger_count, EXTRACT(YEAR FROM pickup_datetime)
ORDER BY passenger_count, pickup_year;
