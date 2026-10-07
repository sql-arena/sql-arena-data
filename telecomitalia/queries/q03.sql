/* Telecom Italia Q03: top 20 Milan squares by internet activity */
SELECT a.square_id,
       g.centroid_lon,
       g.centroid_lat,
       SUM(a.internet) AS internet,
       SUM(a.call_in + a.call_out) AS calls
FROM telecomitalia.sms_call_internet_mi AS a
INNER JOIN telecomitalia.grid_mi AS g
    ON a.square_id = g.square_id
GROUP BY a.square_id, g.centroid_lon, g.centroid_lat
ORDER BY internet DESC, a.square_id
LIMIT 20;
