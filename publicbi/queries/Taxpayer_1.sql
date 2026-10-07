/* Public BI Taxpayer 1 */
SELECT "Taxpayer_1"."nppes_provider_first_name" AS "nppes_provider_first_name" FROM publicbi."Taxpayer_1" WHERE (("Taxpayer_1"."nppes_provider_last_org_name" = 'HOLDER') AND ("Taxpayer_1"."nppes_provider_state" = 'WA')) GROUP BY "Taxpayer_1"."nppes_provider_first_name";
