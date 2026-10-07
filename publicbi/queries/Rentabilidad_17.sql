/* Public BI Rentabilidad 17 */
SELECT "Rentabilidad_1"."Población Distribuidor GVF/GVI" AS "Población Distribuidor GVF/GVI" FROM publicbi."Rentabilidad_1" WHERE (("Rentabilidad_1"."Sede Foraneo Sintec" = 'Foraneo') AND ("Rentabilidad_1"."Zona" = 'NR')) GROUP BY "Rentabilidad_1"."Población Distribuidor GVF/GVI";
