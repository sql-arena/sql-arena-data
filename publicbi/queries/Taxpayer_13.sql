/* Public BI Taxpayer 13 */
SELECT "Taxpayer_7"."nppes_provider_last_org_name" AS "nppes_provider_last_org_name" FROM publicbi."Taxpayer_7" WHERE (("Taxpayer_7"."nppes_provider_first_name" = 'JOHN') AND ("Taxpayer_7"."nppes_provider_state" = 'WA')) GROUP BY "Taxpayer_7"."nppes_provider_last_org_name";
