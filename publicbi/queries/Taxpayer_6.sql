/* Public BI Taxpayer 6 */
SELECT "Taxpayer_10"."nppes_provider_first_name" AS "nppes_provider_first_name" FROM publicbi."Taxpayer_10" WHERE (("Taxpayer_10"."nppes_provider_last_org_name" = 'HOLDER') AND ("Taxpayer_10"."nppes_provider_state" = 'WA')) GROUP BY "Taxpayer_10"."nppes_provider_first_name";
