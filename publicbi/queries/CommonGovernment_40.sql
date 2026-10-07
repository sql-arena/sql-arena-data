/* Public BI CommonGovernment 40 */
SELECT SUM("CommonGovernment_13"."obligatedamount") AS "sum:obligatedamount:ok",   "CommonGovernment_13"."vend_contoffbussizedeterm" AS "vend_contoffbussizedeterm" FROM publicbi."CommonGovernment_13" GROUP BY "CommonGovernment_13"."vend_contoffbussizedeterm";
