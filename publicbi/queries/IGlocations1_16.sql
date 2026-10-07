/* Public BI IGlocations1 16 */
SELECT trim(splitpart("IGlocations1_1"."City", ' ', 1),' \\t\ \\x0b\\f\\r') AS "City - Split 1" FROM publicbi."IGlocations1_1" GROUP BY "City - Split 1" ORDER BY "City - Split 1" ASC ;
