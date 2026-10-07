/* Telecom Italia Q12: Trentino squares with the most foreign activity, e.g. ski resorts */
SELECT a.square_id,
       g.centroid_lon,
       g.centroid_lat,
       SUM(CASE WHEN a.country_code NOT IN (0, 39) THEN a.call_in + a.call_out + a.sms_in + a.sms_out ELSE 0 END) AS foreign_activity,
       SUM(CASE WHEN a.country_code NOT IN (0, 39) THEN a.call_in + a.call_out + a.sms_in + a.sms_out ELSE 0 END)
           / SUM(a.call_in + a.call_out + a.sms_in + a.sms_out) AS foreign_share
FROM telecomitalia.sms_call_internet_tn AS a
INNER JOIN telecomitalia.grid_tn AS g
    ON a.square_id = g.square_id
GROUP BY a.square_id, g.centroid_lon, g.centroid_lat
HAVING SUM(a.call_in + a.call_out + a.sms_in + a.sms_out) > 0
ORDER BY foreign_activity DESC, a.square_id
LIMIT 20;
