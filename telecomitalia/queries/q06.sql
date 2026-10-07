/* Telecom Italia Q06: top 50 Milan origin-destination square pairs */
SELECT f.square_id_1,
       f.square_id_2,
       SUM(f.strength) AS strength,
       SQRT(POWER((g1.centroid_lon - g2.centroid_lon) * 77.0, 2)
            + POWER((g1.centroid_lat - g2.centroid_lat) * 111.1, 2)) AS distance_km
FROM telecomitalia.mi_to_mi AS f
INNER JOIN telecomitalia.grid_mi AS g1
    ON f.square_id_1 = g1.square_id
INNER JOIN telecomitalia.grid_mi AS g2
    ON f.square_id_2 = g2.square_id
WHERE f.square_id_1 <> f.square_id_2
GROUP BY f.square_id_1, f.square_id_2, g1.centroid_lon, g1.centroid_lat, g2.centroid_lon, g2.centroid_lat
ORDER BY strength DESC, f.square_id_1, f.square_id_2
LIMIT 50;
