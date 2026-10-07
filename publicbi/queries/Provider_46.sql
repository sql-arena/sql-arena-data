/* Public BI Provider 46 */
SELECT CAST("Provider_7"."hcpcs_code" AS BIGINT) AS "hcpcs_code" FROM publicbi."Provider_7" GROUP BY "Provider_7"."hcpcs_code",   "Provider_7"."hcpcs_code" ORDER BY "hcpcs_code" ASC ;
