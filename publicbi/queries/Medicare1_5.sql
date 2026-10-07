/* Public BI Medicare1 5 */
SELECT "Medicare1_2"."DRUG_NAME" AS "DRUG_NAME",   AVG(CAST("Medicare1_2"."Calculation_3170826185505725" AS double)) AS "avg:Calculation_3170826185505725:ok" FROM publicbi."Medicare1_2" GROUP BY "Medicare1_2"."DRUG_NAME" ORDER BY "avg:Calculation_3170826185505725:ok" DESC LIMIT 15;
