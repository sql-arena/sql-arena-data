/* Public BI Medicare2 5 */
SELECT "Medicare2_2"."nppes_entity_code" AS "nppes_entity_code" FROM publicbi."Medicare2_2" WHERE ("Medicare2_2"."nppes_provider_state" = 'NY') GROUP BY "Medicare2_2"."nppes_entity_code" ORDER BY "nppes_entity_code" ASC ;
