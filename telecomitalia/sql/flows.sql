-- read_csv appends to the rejects tables, so clear them from the previous chunk
DROP TABLE IF EXISTS _rejects;
DROP TABLE IF EXISTS _reject_scans;

CREATE OR REPLACE TABLE _chunk (
    time_interval TIMESTAMP NOT NULL,
    square_id_1   INTEGER   NOT NULL,
    square_id_2   INTEGER   NOT NULL,
    strength      DOUBLE    NOT NULL
);

INSERT INTO _chunk
SELECT epoch_ms(time_interval), square_id_1, square_id_2, strength
FROM read_csv(%%PATHS%%, delim = '\t', header = false, quote = '', escape = '', auto_detect = false,
              store_rejects = true, rejects_table = '_rejects', rejects_scan = '_reject_scans',
              columns = {'time_interval': 'BIGINT', 'square_id_1': 'INTEGER', 'square_id_2': 'INTEGER',
                         'strength': 'DOUBLE'})
ORDER BY ALL;
