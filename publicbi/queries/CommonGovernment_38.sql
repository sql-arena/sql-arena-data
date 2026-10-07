/* Public BI CommonGovernment 38 */
SELECT SUM("CommonGovernment_12"."obligatedamount") AS "sum:obligatedamount:ok",   "CommonGovernment_12"."vend_contoffbussizedeterm" AS "vend_contoffbussizedeterm" FROM publicbi."CommonGovernment_12" GROUP BY "CommonGovernment_12"."vend_contoffbussizedeterm";
