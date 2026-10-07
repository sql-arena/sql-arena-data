/* Public BI Medicare2 4 */
SELECT "Medicare2_2"."hcpcs_description" AS "hcpcs_description",   "Medicare2_2"."provider_type" AS "provider_type" FROM publicbi."Medicare2_2" WHERE (("Medicare2_2"."nppes_provider_state" = 'NY') AND ("Medicare2_2"."nppes_provider_country" = 'US')) GROUP BY "Medicare2_2"."hcpcs_description",   "Medicare2_2"."provider_type";
