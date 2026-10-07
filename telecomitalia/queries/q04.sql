/* Telecom Italia Q04: top 20 foreign country codes in Milan by call activity */
WITH by_country AS (
    SELECT country_code,
           SUM(call_in + call_out) AS calls,
           SUM(sms_in + sms_out) AS sms,
           COUNT(DISTINCT square_id) AS squares
    FROM telecomitalia.sms_call_internet_mi
    WHERE country_code NOT IN (0, 39)
    GROUP BY country_code
)
SELECT country_code,
       calls,
       sms,
       squares,
       calls / SUM(calls) OVER () AS call_share
FROM by_country
ORDER BY calls DESC, country_code
LIMIT 20;
