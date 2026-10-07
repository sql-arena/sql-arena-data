/* NYC Taxi Q05: yellow trips between boroughs */
SELECT pu.borough AS pickup_borough,
       dz.borough AS dropoff_borough,
       COUNT(*) AS trips,
       AVG(t.trip_distance) AS avg_distance,
       AVG(t.total_amount) AS avg_total_amount
FROM nyctaxi.yellow_tripdata AS t
INNER JOIN nyctaxi.taxi_zone AS pu
    ON t.pu_location_id = pu.location_id
INNER JOIN nyctaxi.taxi_zone AS dz
    ON t.do_location_id = dz.location_id
GROUP BY pu.borough, dz.borough
ORDER BY trips DESC, pickup_borough, dropoff_borough;
