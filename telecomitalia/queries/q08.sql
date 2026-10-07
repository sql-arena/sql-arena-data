/* Telecom Italia Q08: Milan interaction with Italian provinces by day of week */
SELECT province,
       EXTRACT(DOW FROM time_interval + INTERVAL '1' HOUR) AS local_dow,
       SUM(cell_to_province) AS cell_to_province,
       SUM(province_to_cell) AS province_to_cell
FROM telecomitalia.mi_to_provinces
GROUP BY province, EXTRACT(DOW FROM time_interval + INTERVAL '1' HOUR)
ORDER BY province, local_dow;
