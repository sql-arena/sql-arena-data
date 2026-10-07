/* Public BI Rentabilidad 23 */
SELECT "Rentabilidad_3"."Locación" AS "Locación" FROM publicbi."Rentabilidad_3" WHERE (("Rentabilidad_3"."Figura" = 'Preventa On Premise') AND ("Rentabilidad_3"."Sede Foraneo Sintec" = 'Sede') AND ("Rentabilidad_3"."Zona" = 'OC')) GROUP BY "Rentabilidad_3"."Locación";
