/* Public BI IUBLibrary 5 */
SELECT "IUBLibrary_1"."Sh" AS "Sh",   SUM(1) AS "usr:Number of Records:ok" FROM publicbi."IUBLibrary_1" WHERE (CAST(EXTRACT(YEAR FROM "IUBLibrary_1"."DateLastCharged") AS BIGINT) = 1900) GROUP BY "IUBLibrary_1"."Sh";
