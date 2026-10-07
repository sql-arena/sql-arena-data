/* Public BI CommonGovernment 28 */
SELECT COUNT(DISTINCT "CommonGovernment_13"."refidvid_piid") AS "ctd:refidvid_piid:ok",   SUM("CommonGovernment_13"."obligatedamount") AS "sum:obligatedamount:ok" FROM publicbi."CommonGovernment_13" HAVING (COUNT(1) > 0);
