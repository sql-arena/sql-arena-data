/* Telecom Italia Q07: daily Milan interaction strength and share within the same square */
SELECT CAST(time_interval + INTERVAL '1' HOUR AS DATE) AS local_date,
       SUM(strength) AS strength,
       SUM(CASE WHEN square_id_1 = square_id_2 THEN strength ELSE 0 END) / SUM(strength) AS same_square_share,
       COUNT(*) AS square_pairs
FROM telecomitalia.mi_to_mi
GROUP BY CAST(time_interval + INTERVAL '1' HOUR AS DATE)
ORDER BY local_date;
