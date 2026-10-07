/* NYC Taxi Q06: airport pickups per year with credit card tip rate */
SELECT z.zone,
       EXTRACT(YEAR FROM t.pickup_datetime) AS pickup_year,
       COUNT(*) AS trips,
       AVG(t.trip_distance) AS avg_distance,
       SUM(t.tip_amount) / SUM(t.fare_amount) AS tip_rate
FROM nyctaxi.yellow_tripdata AS t
INNER JOIN nyctaxi.taxi_zone AS z
    ON t.pu_location_id = z.location_id
WHERE z.service_zone = 'Airports'
  AND t.payment_type = 1
  AND t.fare_amount > 0
GROUP BY z.zone, EXTRACT(YEAR FROM t.pickup_datetime)
ORDER BY z.zone, pickup_year;
