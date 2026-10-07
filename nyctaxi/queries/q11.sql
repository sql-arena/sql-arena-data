/* NYC Taxi Q11: driver pay as a share of passenger fare per service and year */
SELECT hvfhs_license_num,
       EXTRACT(YEAR FROM pickup_datetime) AS pickup_year,
       COUNT(*) AS trips,
       SUM(driver_pay) / SUM(base_passenger_fare) AS driver_pay_ratio,
       SUM(tips) / SUM(base_passenger_fare) AS tip_ratio
FROM nyctaxi.fhvhv_tripdata
WHERE base_passenger_fare > 0
GROUP BY hvfhs_license_num, EXTRACT(YEAR FROM pickup_datetime)
ORDER BY hvfhs_license_num, pickup_year;
