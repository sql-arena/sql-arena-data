/* Public BI TrainsUK2 17 */
SELECT SUM(CAST("TrainsUK2_2"."Number of Records" AS BIGINT)) AS "sum:Number of Records:ok" FROM publicbi."TrainsUK2_2" HAVING (COUNT(1) > 0);
