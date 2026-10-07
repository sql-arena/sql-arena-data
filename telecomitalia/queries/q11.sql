/* Telecom Italia Q11: Milan squares with the most weekend-heavy internet use */
WITH daily AS (
    SELECT square_id,
           CAST(time_interval + INTERVAL '1' HOUR AS DATE) AS local_date,
           CASE WHEN EXTRACT(DOW FROM time_interval + INTERVAL '1' HOUR) IN (0, 6) THEN 1 ELSE 0 END AS is_weekend,
           SUM(internet) AS internet
    FROM telecomitalia.sms_call_internet_mi
    GROUP BY square_id,
             CAST(time_interval + INTERVAL '1' HOUR AS DATE),
             CASE WHEN EXTRACT(DOW FROM time_interval + INTERVAL '1' HOUR) IN (0, 6) THEN 1 ELSE 0 END
),
by_square AS (
    SELECT square_id,
           AVG(CASE WHEN is_weekend = 1 THEN internet END) AS weekend_internet,
           AVG(CASE WHEN is_weekend = 0 THEN internet END) AS weekday_internet
    FROM daily
    GROUP BY square_id
)
SELECT b.square_id,
       g.centroid_lon,
       g.centroid_lat,
       b.weekend_internet,
       b.weekday_internet,
       b.weekend_internet / b.weekday_internet AS weekend_ratio
FROM by_square AS b
INNER JOIN telecomitalia.grid_mi AS g
    ON b.square_id = g.square_id
WHERE b.weekday_internet > 100
ORDER BY weekend_ratio DESC, b.square_id
LIMIT 20;
