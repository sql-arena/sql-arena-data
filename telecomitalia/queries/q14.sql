/* Telecom Italia Q14: local hour of each Milan square's busiest 10 minute slot */
WITH slots AS (
    SELECT square_id,
           time_interval,
           SUM(call_in + call_out + sms_in + sms_out) AS activity
    FROM telecomitalia.sms_call_internet_mi
    GROUP BY square_id, time_interval
),
ranked AS (
    SELECT square_id,
           time_interval,
           ROW_NUMBER() OVER (PARTITION BY square_id ORDER BY activity DESC, time_interval) AS slot_rank
    FROM slots
)
SELECT EXTRACT(HOUR FROM time_interval + INTERVAL '1' HOUR) AS local_hour,
       COUNT(*) AS squares
FROM ranked
WHERE slot_rank = 1
GROUP BY EXTRACT(HOUR FROM time_interval + INTERVAL '1' HOUR)
ORDER BY local_hour;
