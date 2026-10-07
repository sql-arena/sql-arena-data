/* Public BI MulheresMil 13 */
SELECT CAST(EXTRACT(YEAR FROM "MulheresMil_1"."data_de_inicio") AS BIGINT) AS "yr:data_de_inicio:ok" FROM publicbi."MulheresMil_1" GROUP BY "yr:data_de_inicio:ok" ORDER BY "yr:data_de_inicio:ok" ASC ;
