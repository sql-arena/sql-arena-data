/* Public BI Rentabilidad 25 */
SELECT "Rentabilidad_5"."Figura" AS "Figura" FROM publicbi."Rentabilidad_5" WHERE (("Rentabilidad_5"."Sede Foraneo Sintec" = 'Sede') AND ("Rentabilidad_5"."Zona" = 'OC')) GROUP BY "Rentabilidad_5"."Figura";
