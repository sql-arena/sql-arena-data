/* Public BI MLB 57 */
SELECT CAST("MLB_14"."year" AS BIGINT) AS "year" FROM publicbi."MLB_14" GROUP BY "MLB_14"."year",   "MLB_14"."year" ORDER BY "year" ASC ;
