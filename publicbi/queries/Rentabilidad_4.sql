/* Public BI Rentabilidad 4 */
SELECT "Rentabilidad_1"."Figura" AS "Figura" FROM publicbi."Rentabilidad_1" WHERE (("Rentabilidad_1"."Sede Foraneo Sintec" = 'Sede') AND ("Rentabilidad_1"."Zona" = 'OC')) GROUP BY "Rentabilidad_1"."Figura";
