/* Public BI Taxpayer 9 */
SELECT "Taxpayer_3"."nppes_provider_state" AS "nppes_provider_state" FROM publicbi."Taxpayer_3" WHERE (("Taxpayer_3"."nppes_provider_first_name" = 'JOHN') AND ("Taxpayer_3"."nppes_provider_last_org_name" = 'HOLDER')) GROUP BY "Taxpayer_3"."nppes_provider_state";
