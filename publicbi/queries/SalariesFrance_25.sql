/* Public BI SalariesFrance 25 */
SELECT AVG(CAST(CAST("SalariesFrance_13"."Calculation_163536984210948109" AS BIGINT) AS double)) AS "avg:Calculation_163536984210948109:ok" FROM publicbi."SalariesFrance_13" WHERE ("SalariesFrance_13"."REG_LIB" = 'NOUVELLE-AQUITAINE') HAVING (COUNT(1) > 0);
