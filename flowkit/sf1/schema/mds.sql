CREATE TABLE flowkit_sf1.mds (
    id VARCHAR NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    duration DOUBLE NOT NULL,
    volume_total DOUBLE NOT NULL,
    volume_upload DOUBLE NOT NULL,
    volume_download DOUBLE NOT NULL,
    msisdn VARCHAR NOT NULL,
    location_id VARCHAR NOT NULL,
    imsi VARCHAR NOT NULL,
    imei VARCHAR NOT NULL,
    tac BIGINT NOT NULL,
    operator_code INT NULL,
    country_code INT NULL
);
