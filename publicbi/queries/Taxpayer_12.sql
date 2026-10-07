/* Public BI Taxpayer 12 */
SELECT "Taxpayer_6"."nppes_provider_city" AS "nppes_provider_city" FROM publicbi."Taxpayer_6" WHERE (("Taxpayer_6"."hcpcs_description" = 'Initial hospital care') AND ("Taxpayer_6"."nppes_provider_state" = 'WA')) GROUP BY "Taxpayer_6"."nppes_provider_city";
