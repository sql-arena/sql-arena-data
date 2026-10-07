/* Telecom Italia Q05: roaming calls per country code, November versus the Christmas weeks */
SELECT country_code,
       SUM(CASE WHEN time_interval < TIMESTAMP '2013-11-30 23:00:00' THEN call_in + call_out ELSE 0 END) AS november_calls,
       SUM(CASE WHEN time_interval >= TIMESTAMP '2013-12-19 23:00:00' THEN call_in + call_out ELSE 0 END) AS christmas_calls
FROM telecomitalia.sms_call_internet_mi
WHERE country_code NOT IN (0, 39)
GROUP BY country_code
HAVING SUM(call_in + call_out) > 0
ORDER BY christmas_calls DESC, country_code;
