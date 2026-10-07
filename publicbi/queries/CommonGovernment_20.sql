/* Public BI CommonGovernment 20 */
SELECT "CommonGovernment_9"."level1_category" AS "level1_category",   SUM("CommonGovernment_9"."obligatedamount") AS "sum:obligatedamount:ok" FROM publicbi."CommonGovernment_9" GROUP BY "CommonGovernment_9"."level1_category";
