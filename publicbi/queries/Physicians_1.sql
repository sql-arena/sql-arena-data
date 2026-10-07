/* Public BI Physicians 1 */
SELECT "Physicians_1"."hcpcs_description" AS "hcpcs_description",   SUM("Physicians_1"."average_Medicare_payment_amt") AS "sum:average_Medicare_payment_amt:ok" FROM publicbi."Physicians_1" GROUP BY "Physicians_1"."hcpcs_description";
