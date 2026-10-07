/* NYC Taxi Q09: monthly market share of high volume for-hire services */
WITH monthly AS (
    SELECT hvfhs_license_num,
           EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
           EXTRACT(MONTH FROM pickup_datetime) AS pickup_month,
           COUNT(*) AS trips
    FROM nyctaxi.fhvhv_tripdata
    GROUP BY hvfhs_license_num, EXTRACT(YEAR FROM pickup_datetime), EXTRACT(MONTH FROM pickup_datetime)
)
SELECT pickup_year,
       pickup_month,
       hvfhs_license_num,
       trips,
       CAST(trips AS DOUBLE) / SUM(trips) OVER (PARTITION BY pickup_year, pickup_month) AS market_share
FROM monthly
ORDER BY pickup_year, pickup_month, hvfhs_license_num;
