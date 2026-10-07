-- read_csv appends to the rejects tables, so clear them from the previous chunk
DROP TABLE IF EXISTS _rejects;
DROP TABLE IF EXISTS _reject_scans;

CREATE OR REPLACE TABLE _chunk (
    square_id     INTEGER   NOT NULL,
    time_interval TIMESTAMP NOT NULL,
    country_code  INTEGER   NOT NULL,
    sms_in        DOUBLE,
    sms_out       DOUBLE,
    call_in       DOUBLE,
    call_out      DOUBLE,
    internet      DOUBLE
);

INSERT INTO _chunk
SELECT square_id, epoch_ms(time_interval), country_code, sms_in, sms_out, call_in, call_out, internet
FROM read_csv(%%PATHS%%, delim = '\t', header = false, quote = '', escape = '', auto_detect = false,
              store_rejects = true, rejects_table = '_rejects', rejects_scan = '_reject_scans',
              columns = {'square_id': 'INTEGER', 'time_interval': 'BIGINT', 'country_code': 'INTEGER',
                         'sms_in': 'DOUBLE', 'sms_out': 'DOUBLE', 'call_in': 'DOUBLE', 'call_out': 'DOUBLE',
                         'internet': 'DOUBLE'})
ORDER BY ALL;
