CREATE TABLE flowkit_sf1.sms (
    id VARCHAR NOT NULL,
    outgoing BOOLEAN NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    network VARCHAR NULL,
    msisdn VARCHAR NOT NULL,
    msisdn_counterpart VARCHAR NOT NULL,
    location_id VARCHAR NOT NULL,
    imsi VARCHAR NOT NULL,
    imei VARCHAR NOT NULL,
    tac BIGINT NOT NULL,
    operator_code INT NULL,
    country_code INT NULL
);
