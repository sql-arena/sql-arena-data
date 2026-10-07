-- The date or timestamp column of a table that its workbook's queries reference most often, else the first one
SELECT '"' || c.column_name || '"'
FROM information_schema.columns c
LEFT JOIN _queries q ON contains(q.query, '"%%TABLE%%"."' || c.column_name || '"')
WHERE c.table_name = '%%TABLE%%' AND c.data_type IN ('DATE', 'TIMESTAMP')
GROUP BY c.column_name, c.ordinal_position
ORDER BY count(q.query) DESC, c.ordinal_position
LIMIT 1;
