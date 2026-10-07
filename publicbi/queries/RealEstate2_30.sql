/* Public BI RealEstate2 30 */
SELECT CAST(EXTRACT(MONTH FROM "RealEstate2_7"."Date_of_Transfer") AS BIGINT) AS "mn:Date_of_Transfer:ok" FROM publicbi."RealEstate2_7" GROUP BY "mn:Date_of_Transfer:ok";
