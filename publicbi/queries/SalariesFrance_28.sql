/* Public BI SalariesFrance 28 */
SELECT SUM("SalariesFrance_13"."SALAIRE_VF") AS "TEMP(Calculation_393783518251319297)(57485518)(0)",   COUNT("SalariesFrance_13"."SALAIRE_VF") AS "TEMP(Calculation_393783518251319297)(879651027)(0)" FROM publicbi."SalariesFrance_13" WHERE ("SalariesFrance_13"."REG_LIB" = 'BOURGOGNE-FRANCHE-COMTÉ') HAVING (COUNT(1) > 0);
