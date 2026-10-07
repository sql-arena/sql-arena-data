SELECT table_name
FROM information_schema.tables
WHERE table_schema = '%%SCHEMA%%'
ORDER BY table_name;
