/* NYC Taxi Q15: suspicious yellow trip records per year */
SELECT EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
       COUNT(*) AS trips,
       SUM(CASE WHEN total_amount < 0 THEN 1 ELSE 0 END) AS negative_amount,
       SUM(CASE WHEN trip_distance > 100 THEN 1 ELSE 0 END) AS over_100_miles,
       SUM(CASE WHEN dropoff_datetime < pickup_datetime THEN 1 ELSE 0 END) AS negative_duration,
       SUM(CASE WHEN passenger_count IS NULL OR passenger_count = 0 THEN 1 ELSE 0 END) AS no_passengers
FROM nyctaxi.yellow_tripdata
GROUP BY EXTRACT(YEAR FROM pickup_datetime)
ORDER BY pickup_year;
