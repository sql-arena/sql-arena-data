/* NYC Taxi Q04: trips by passenger count, year and whole miles */
SELECT passenger_count,
       EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
       CAST(FLOOR(trip_distance) AS INTEGER) AS distance_miles,
       COUNT(*) AS trips
FROM nyctaxi.yellow_tripdata
GROUP BY passenger_count, EXTRACT(YEAR FROM pickup_datetime), CAST(FLOOR(trip_distance) AS INTEGER)
ORDER BY pickup_year, trips DESC, passenger_count, distance_miles;
