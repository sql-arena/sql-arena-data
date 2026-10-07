/* Public BI Provider 3 */
SELECT "Provider_3"."nppes_provider_street1" AS "nppes_provider_street1" FROM publicbi."Provider_3" WHERE (("Provider_3"."nppes_provider_state" = 'WA') AND ("Provider_3"."provider_type" = 'Nephrology')) GROUP BY "Provider_3"."nppes_provider_street1";
