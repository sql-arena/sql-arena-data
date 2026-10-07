/* NYC Taxi Q14: daily yellow and green trips in 2019 with a 7 day moving average */
WITH trips AS (
    SELECT pickup_datetime FROM nyctaxi.yellow_tripdata
    UNION ALL
    SELECT pickup_datetime FROM nyctaxi.green_tripdata
),
daily AS (
    SELECT CAST(pickup_datetime AS DATE) AS pickup_date,
           COUNT(*) AS trips
    FROM trips
    WHERE pickup_datetime >= TIMESTAMP '2019-01-01 00:00:00'
      AND pickup_datetime < TIMESTAMP '2020-01-01 00:00:00'
    GROUP BY CAST(pickup_datetime AS DATE)
)
SELECT pickup_date,
       trips,
       AVG(trips) OVER (ORDER BY pickup_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS trips_7day_avg
FROM daily
ORDER BY pickup_date;
