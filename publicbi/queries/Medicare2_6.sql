/* Public BI Medicare2 6 */
SELECT "Medicare2_2"."provider_type" AS "provider_type" FROM publicbi."Medicare2_2" WHERE ("Medicare2_2"."nppes_provider_state" = 'NY') GROUP BY "Medicare2_2"."provider_type" ORDER BY "provider_type" ASC ;
