/* Public BI MLB 104 */
SELECT CAST(MIN("MLB_44"."PA") AS BIGINT) AS "TEMP(none:PA:qk lower)(290714814)(1)",   CAST(MAX("MLB_44"."PA") AS BIGINT) AS "TEMP(none:PA:qk upper)(290714814)(1)" FROM publicbi."MLB_44" HAVING (COUNT(1) > 0);
