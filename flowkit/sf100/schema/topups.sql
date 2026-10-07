CREATE TABLE flowkit_sf100.topups (
    id VARCHAR NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    type VARCHAR NOT NULL,
    recharge_amount DECIMAL(12,2) NOT NULL,
    airtime_fee DECIMAL(12,2) NOT NULL,
    tax_and_fee DECIMAL(12,2) NOT NULL,
    pre_event_balance DECIMAL(12,2) NOT NULL,
    post_event_balance DECIMAL(12,2) NOT NULL,
    msisdn VARCHAR NOT NULL,
    location_id VARCHAR NOT NULL,
    imsi VARCHAR NOT NULL,
    imei VARCHAR NOT NULL,
    tac BIGINT NOT NULL,
    operator_code INT NULL,
    country_code INT NULL
);
