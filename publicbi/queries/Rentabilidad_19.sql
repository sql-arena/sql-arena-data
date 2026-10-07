/* Public BI Rentabilidad 19 */
SELECT "Rentabilidad_1"."Ruta de Venta" AS "Ruta de Venta" FROM publicbi."Rentabilidad_1" WHERE (("Rentabilidad_1"."Locación" = 'Bogota Sur') AND ("Rentabilidad_1"."Zona" = 'CE')) GROUP BY "Rentabilidad_1"."Ruta de Venta";
