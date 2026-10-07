/* Public BI CommonGovernment 29 */
SELECT COUNT(DISTINCT "CommonGovernment_13"."refidvid_piid") AS "ctd:refidvid_piid:ok",   SUM("CommonGovernment_13"."obligatedamount") AS "sum:obligatedamount:ok",   "CommonGovernment_13"."vend_dunsnumber" AS "vend_dunsnumber" FROM publicbi."CommonGovernment_13" GROUP BY "CommonGovernment_13"."vend_dunsnumber";
