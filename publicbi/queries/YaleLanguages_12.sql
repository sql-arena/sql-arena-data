/* Public BI YaleLanguages 12 */
SELECT "YaleLanguages_3"."Patron Group" AS "Patron Group" FROM publicbi."YaleLanguages_3" WHERE ((CAST("YaleLanguages_3"."CHARGE_DATE" as DATE) >= cast('2002-01-01' as DATE)) AND ("YaleLanguages_3"."PATRON_TYPE (Pseudo vs Patron)" = 'Patron')) GROUP BY "Patron Group";
