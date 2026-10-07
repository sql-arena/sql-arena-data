/* Telecom Italia Q02: Milan hourly profile on weekdays and weekends */
SELECT CASE WHEN EXTRACT(DOW FROM time_interval + INTERVAL '1' HOUR) IN (0, 6) THEN 'weekend' ELSE 'weekday' END AS day_type,
       EXTRACT(HOUR FROM time_interval + INTERVAL '1' HOUR) AS local_hour,
       SUM(sms_in + sms_out) AS sms,
       SUM(call_in + call_out) AS calls,
       SUM(internet) AS internet
FROM telecomitalia.sms_call_internet_mi
GROUP BY CASE WHEN EXTRACT(DOW FROM time_interval + INTERVAL '1' HOUR) IN (0, 6) THEN 'weekend' ELSE 'weekday' END,
         EXTRACT(HOUR FROM time_interval + INTERVAL '1' HOUR)
ORDER BY day_type, local_hour;
