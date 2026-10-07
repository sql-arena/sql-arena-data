CREATE TABLE tpcds_sf1000.customer_address (
    ca_address_sk BIGINT NOT NULL,
    ca_address_id VARCHAR NOT NULL,
    ca_street_number VARCHAR NULL,
    ca_street_name VARCHAR NULL,
    ca_street_type VARCHAR NULL,
    ca_suite_number VARCHAR NULL,
    ca_city VARCHAR NULL,
    ca_county VARCHAR NULL,
    ca_state VARCHAR NULL,
    ca_zip VARCHAR NULL,
    ca_country VARCHAR NULL,
    ca_gmt_offset DECIMAL(5,2) NULL,
    ca_location_type VARCHAR NULL
);
