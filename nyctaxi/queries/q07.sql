/* NYC Taxi Q07: credit card tip rate by hour of day and day of week */
SELECT EXTRACT(DOW FROM pickup_datetime) AS pickup_dow,
       EXTRACT(HOUR FROM pickup_datetime) AS pickup_hour,
       COUNT(*) AS trips,
       SUM(tip_amount) / SUM(fare_amount) AS tip_rate
FROM nyctaxi.yellow_tripdata
WHERE payment_type = 1
  AND fare_amount > 0
  AND pickup_datetime >= TIMESTAMP '2019-01-01 00:00:00'
  AND pickup_datetime < TIMESTAMP '2020-01-01 00:00:00'
GROUP BY EXTRACT(DOW FROM pickup_datetime), EXTRACT(HOUR FROM pickup_datetime)
ORDER BY pickup_dow, pickup_hour;
