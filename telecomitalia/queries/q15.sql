/* Telecom Italia Q15: Milan and Trentino squares and 10 minute slots reported per day */
SELECT 'milan' AS region,
       CAST(time_interval + INTERVAL '1' HOUR AS DATE) AS local_date,
       COUNT(DISTINCT time_interval) AS slots,
       COUNT(DISTINCT square_id) AS squares,
       COUNT(*) AS row_count
FROM telecomitalia.sms_call_internet_mi
GROUP BY CAST(time_interval + INTERVAL '1' HOUR AS DATE)
UNION ALL
SELECT 'trentino',
       CAST(time_interval + INTERVAL '1' HOUR AS DATE),
       COUNT(DISTINCT time_interval),
       COUNT(DISTINCT square_id),
       COUNT(*)
FROM telecomitalia.sms_call_internet_tn
GROUP BY CAST(time_interval + INTERVAL '1' HOUR AS DATE)
ORDER BY region, local_date;
