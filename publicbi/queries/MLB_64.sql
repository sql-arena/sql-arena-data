/* Public BI MLB 64 */
SELECT CAST("MLB_18"."year" AS BIGINT) AS "year" FROM publicbi."MLB_18" GROUP BY "MLB_18"."year",   "MLB_18"."year" ORDER BY "year" ASC ;
