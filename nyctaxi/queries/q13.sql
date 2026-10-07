/* NYC Taxi Q13: 2009-2010 yellow trips starting in Manhattan by year and payment type */
SELECT EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
       UPPER(payment_type) AS payment_type,
       COUNT(*) AS trips,
       AVG(fare_amount) AS avg_fare,
       AVG(tip_amount) AS avg_tip
FROM nyctaxi.yellow_tripdata_legacy
WHERE pickup_longitude BETWEEN -74.03 AND -73.90
  AND pickup_latitude BETWEEN 40.69 AND 40.88
GROUP BY EXTRACT(YEAR FROM pickup_datetime), UPPER(payment_type)
ORDER BY pickup_year, trips DESC, payment_type;
