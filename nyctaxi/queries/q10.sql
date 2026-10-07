/* NYC Taxi Q10: yellow taxi versus high volume for-hire pickups per zone in 2023 */
WITH yellow AS (
    SELECT pu_location_id, COUNT(*) AS trips
    FROM nyctaxi.yellow_tripdata
    WHERE pickup_datetime >= TIMESTAMP '2023-01-01 00:00:00'
      AND pickup_datetime < TIMESTAMP '2024-01-01 00:00:00'
    GROUP BY pu_location_id
),
fhvhv AS (
    SELECT pu_location_id, COUNT(*) AS trips
    FROM nyctaxi.fhvhv_tripdata
    WHERE pickup_datetime >= TIMESTAMP '2023-01-01 00:00:00'
      AND pickup_datetime < TIMESTAMP '2024-01-01 00:00:00'
    GROUP BY pu_location_id
)
SELECT z.borough,
       z.zone,
       COALESCE(y.trips, 0) AS yellow_trips,
       COALESCE(f.trips, 0) AS fhvhv_trips,
       CAST(COALESCE(y.trips, 0) AS DOUBLE) / (COALESCE(y.trips, 0) + COALESCE(f.trips, 0)) AS yellow_share
FROM yellow AS y
FULL OUTER JOIN fhvhv AS f
    ON y.pu_location_id = f.pu_location_id
INNER JOIN nyctaxi.taxi_zone AS z
    ON z.location_id = COALESCE(y.pu_location_id, f.pu_location_id)
ORDER BY yellow_share DESC, z.borough, z.zone;
