/* Public BI Provider 8 */
SELECT "Provider_8"."nppes_provider_city" AS "nppes_provider_city" FROM publicbi."Provider_8" WHERE (("Provider_8"."nppes_provider_state" = 'RI') AND ("Provider_8"."provider_type" = 'Diagnostic Radiology')) GROUP BY "Provider_8"."nppes_provider_city";
