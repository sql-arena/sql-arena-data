/* Public BI Taxpayer 8 */
SELECT "Taxpayer_2"."nppes_provider_last_org_name" AS "nppes_provider_last_org_name" FROM publicbi."Taxpayer_2" WHERE (("Taxpayer_2"."nppes_provider_first_name" = 'JOHN') AND ("Taxpayer_2"."nppes_provider_state" = 'WA')) GROUP BY "Taxpayer_2"."nppes_provider_last_org_name";
