-- Copy %%COPY%% of the haystack in time order: another branch office, with its internal addresses moved from
-- 192.168.0.0/16 to 10.%%COPY%%.0.0/16 and its host names suffixed. The attack events are not copied.
CREATE OR REPLACE TABLE _export AS
SELECT %%COLUMNS%% FROM _flat WHERE _haystack ORDER BY _time, _line;
