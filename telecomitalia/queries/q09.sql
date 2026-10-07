/* Telecom Italia Q09: interaction with each province from Milan and from Trentino */
WITH mi AS (
    SELECT province, SUM(cell_to_province + province_to_cell) AS strength
    FROM telecomitalia.mi_to_provinces
    GROUP BY province
),
tn AS (
    SELECT province, SUM(cell_to_province + province_to_cell) AS strength
    FROM telecomitalia.tn_to_provinces
    GROUP BY province
)
SELECT COALESCE(mi.province, tn.province) AS province,
       mi.strength AS milan_strength,
       tn.strength AS trentino_strength,
       RANK() OVER (ORDER BY mi.strength DESC) AS milan_rank,
       RANK() OVER (ORDER BY tn.strength DESC) AS trentino_rank
FROM mi
FULL OUTER JOIN tn
    ON mi.province = tn.province
ORDER BY province;
