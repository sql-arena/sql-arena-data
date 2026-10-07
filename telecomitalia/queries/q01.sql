/* Telecom Italia Q01: daily Milan activity in Italian time */
SELECT CAST(time_interval + INTERVAL '1' HOUR AS DATE) AS local_date,
       SUM(sms_in) AS sms_in,
       SUM(sms_out) AS sms_out,
       SUM(call_in) AS call_in,
       SUM(call_out) AS call_out,
       SUM(internet) AS internet
FROM telecomitalia.sms_call_internet_mi
GROUP BY CAST(time_interval + INTERVAL '1' HOUR AS DATE)
ORDER BY local_date;
