/* Public BI CommonGovernment 41 */
SELECT SUM("CommonGovernment_13"."obligatedamount") AS "sum:obligatedamount:ok",   "CommonGovernment_13"."vend_vendorname" AS "vend_vendorname" FROM publicbi."CommonGovernment_13" GROUP BY "CommonGovernment_13"."vend_vendorname";
