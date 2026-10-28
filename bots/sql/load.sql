-- One row per event, with the columns of fields.csv taken from v, the event's values at %%PATHS%%.
-- Splunk's _time is local time (MDT) to the millisecond; _subsecond, when present, has the microseconds.
-- _haystack marks the events outside the attack-only set, and _line keeps the file order to break ties in time.
CREATE OR REPLACE TABLE _flat AS
SELECT CAST(regexp_replace(v[%%TIME%%] ->> '$', '(\.[0-9]+)? MDT$', '')
            || coalesce(v[%%SUBSECOND%%] ->> '$', regexp_extract(v[%%TIME%%] ->> '$', '(\.[0-9]+) MDT$', 1))
            || '-06' AS TIMESTAMPTZ) AS _time,
       %%COLUMNS%%,
       (v[%%BUCKET%%] ->> '$') LIKE 'botsv1~59~%' AS _haystack,
       _line
FROM (SELECT json_extract(r, %%PATHS%%) AS v, _line
      FROM (SELECT json -> 'result' AS r, row_number() OVER () AS _line FROM read_ndjson_objects('%%FILE%%'))
      WHERE r IS NOT NULL);
SELECT count(*) AS events, count(*) FILTER (_time IS NULL) AS no_time, count(*) FILTER (_haystack) AS haystack FROM _flat;
