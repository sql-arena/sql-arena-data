/* NYC Taxi Q02: average total amount by passenger count */
SELECT passenger_count,
       AVG(total_amount) AS avg_total_amount
FROM nyctaxi.yellow_tripdata
GROUP BY passenger_count
ORDER BY passenger_count;
