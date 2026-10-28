-- Every key of the events' result objects, with how often its value is an array, an integer or a decimal
CREATE OR REPLACE TEMP TABLE _keys AS
SELECT e.key,
       count(*) AS n,
       count(*) FILTER (e.type = 'ARRAY') AS arrays,
       count(*) FILTER (regexp_full_match(e.value ->> '$', '-?(0|[1-9][0-9]{0,17})')) AS integers,
       count(*) FILTER (regexp_full_match(e.value ->> '$', '-?[0-9]+\.[0-9]+')) AS decimals
FROM (SELECT json -> 'result' AS r FROM read_ndjson_objects('%%FILE%%')) AS events, json_each(events.r) AS e
WHERE events.r IS NOT NULL
GROUP BY e.key;
SELECT key, n, arrays, integers, decimals FROM _keys ORDER BY key;
