/* Public BI Provider 26 */
SELECT "Provider_8"."nppes_provider_state" AS "nppes_provider_state",   "Provider_8"."provider_type" AS "provider_type" FROM publicbi."Provider_8" WHERE ("Provider_8"."nppes_provider_city" = 'GREENVILLE') GROUP BY "Provider_8"."nppes_provider_state",   "Provider_8"."provider_type";
