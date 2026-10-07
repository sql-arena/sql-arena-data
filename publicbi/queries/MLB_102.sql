/* Public BI MLB 102 */
SELECT CAST(MIN("MLB_17"."PA") AS BIGINT) AS "TEMP(none:PA:qk lower)(290714814)(1)",   CAST(MAX("MLB_17"."PA") AS BIGINT) AS "TEMP(none:PA:qk upper)(290714814)(1)" FROM publicbi."MLB_17" HAVING (COUNT(1) > 0);
