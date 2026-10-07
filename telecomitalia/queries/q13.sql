/* Telecom Italia Q13: Trentino interaction strength by distance between squares */
WITH pairs AS (
    SELECT f.strength,
           SQRT(POWER((g1.centroid_lon - g2.centroid_lon) * 77.0, 2)
                + POWER((g1.centroid_lat - g2.centroid_lat) * 111.1, 2)) AS distance_km
    FROM telecomitalia.tn_to_tn AS f
    INNER JOIN telecomitalia.grid_tn AS g1
        ON f.square_id_1 = g1.square_id
    INNER JOIN telecomitalia.grid_tn AS g2
        ON f.square_id_2 = g2.square_id
)
SELECT CAST(FLOOR(distance_km / 5) * 5 AS INTEGER) AS distance_km_from,
       COUNT(*) AS pair_slots,
       SUM(strength) AS strength,
       AVG(strength) AS avg_strength
FROM pairs
GROUP BY CAST(FLOOR(distance_km / 5) * 5 AS INTEGER)
ORDER BY distance_km_from;
