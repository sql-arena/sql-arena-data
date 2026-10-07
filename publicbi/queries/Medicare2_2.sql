/* Public BI Medicare2 2 */
SELECT "Medicare2_2"."hcpcs_description" AS "hcpcs_description" FROM publicbi."Medicare2_2" WHERE ("Medicare2_2"."nppes_provider_state" = 'NY') GROUP BY "Medicare2_2"."hcpcs_description" ORDER BY "hcpcs_description" ASC ;
