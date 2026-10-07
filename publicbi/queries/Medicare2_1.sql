/* Public BI Medicare2 1 */
SELECT "Medicare2_1"."provider_type" AS "provider_type" FROM publicbi."Medicare2_1" WHERE ("Medicare2_1"."nppes_provider_state" = 'NY') GROUP BY "Medicare2_1"."provider_type" ORDER BY "provider_type" ASC ;
