-- read_csv appends to the rejects tables, so clear them from the previous chunk
DROP TABLE IF EXISTS _rejects;
DROP TABLE IF EXISTS _reject_scans;

CREATE OR REPLACE TABLE _chunk (
    time_interval    TIMESTAMP NOT NULL,
    square_id        INTEGER   NOT NULL,
    province         VARCHAR   NOT NULL,
    cell_to_province DOUBLE,
    province_to_cell DOUBLE
);

INSERT INTO _chunk
SELECT epoch_ms(time_interval), square_id, province, cell_to_province, province_to_cell
FROM read_csv(%%PATHS%%, delim = '\t', header = false, quote = '', escape = '', auto_detect = false,
              store_rejects = true, rejects_table = '_rejects', rejects_scan = '_reject_scans',
              columns = {'square_id': 'INTEGER', 'province': 'VARCHAR', 'time_interval': 'BIGINT',
                         'cell_to_province': 'DOUBLE', 'province_to_cell': 'DOUBLE'})
ORDER BY ALL;
