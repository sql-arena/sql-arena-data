/* Public BI MLB 69 */
SELECT CAST("MLB_24"."inning" AS BIGINT) AS "inning" FROM publicbi."MLB_24" GROUP BY "MLB_24"."inning",   "MLB_24"."inning" ORDER BY "inning" ASC ;
