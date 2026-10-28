-- The original events in time order
CREATE OR REPLACE TABLE _export AS
SELECT %%COLUMNS%% FROM _flat ORDER BY _time, _line;
