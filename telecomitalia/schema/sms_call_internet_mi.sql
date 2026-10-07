CREATE TABLE telecomitalia.sms_call_internet_mi (
    square_id INT NOT NULL,
    time_interval TIMESTAMP NOT NULL,
    country_code INT NOT NULL,
    sms_in DOUBLE NULL,
    sms_out DOUBLE NULL,
    call_in DOUBLE NULL,
    call_out DOUBLE NULL,
    internet DOUBLE NULL
);
