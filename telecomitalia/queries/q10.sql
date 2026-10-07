/* Telecom Italia Q10: Milan activity per 10 minutes around New Year's Eve midnight */
SELECT time_interval + INTERVAL '1' HOUR AS local_time,
       SUM(sms_out) AS sms_out,
       SUM(call_out) AS call_out,
       SUM(internet) AS internet
FROM telecomitalia.sms_call_internet_mi
WHERE time_interval >= TIMESTAMP '2013-12-31 21:00:00'
  AND time_interval < TIMESTAMP '2014-01-01 01:00:00'
GROUP BY time_interval
ORDER BY local_time;
