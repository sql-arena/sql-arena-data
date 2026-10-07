/* NYC Taxi Q08: top 5 pickup zones per borough for green and yellow taxis */
WITH trips AS (
    SELECT pu_location_id FROM nyctaxi.yellow_tripdata
    UNION ALL
    SELECT pu_location_id FROM nyctaxi.green_tripdata
),
zone_trips AS (
    SELECT z.borough,
           z.zone,
           COUNT(*) AS trips
    FROM trips AS t
    INNER JOIN nyctaxi.taxi_zone AS z
        ON t.pu_location_id = z.location_id
    GROUP BY z.borough, z.zone
),
ranked AS (
    SELECT borough,
           zone,
           trips,
           ROW_NUMBER() OVER (PARTITION BY borough ORDER BY trips DESC, zone) AS zone_rank
    FROM zone_trips
)
SELECT borough, zone_rank, zone, trips
FROM ranked
WHERE zone_rank <= 5
ORDER BY borough, zone_rank;
