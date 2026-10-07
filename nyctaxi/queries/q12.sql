/* NYC Taxi Q12: average high volume for-hire speed by pickup borough and hour */
SELECT z.borough,
       EXTRACT(HOUR FROM t.pickup_datetime) AS pickup_hour,
       COUNT(*) AS trips,
       SUM(t.trip_miles) / (SUM(t.trip_time) / 3600.0) AS avg_mph
FROM nyctaxi.fhvhv_tripdata AS t
INNER JOIN nyctaxi.taxi_zone AS z
    ON t.pu_location_id = z.location_id
WHERE t.trip_time > 0
GROUP BY z.borough, EXTRACT(HOUR FROM t.pickup_datetime)
ORDER BY z.borough, pickup_hour;
