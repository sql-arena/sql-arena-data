CREATE TABLE tpcds_sf1.warehouse (
    w_warehouse_sk BIGINT NOT NULL,
    w_warehouse_id VARCHAR NOT NULL,
    w_warehouse_name VARCHAR NULL,
    w_warehouse_sq_ft BIGINT NULL,
    w_street_number VARCHAR NULL,
    w_street_name VARCHAR NULL,
    w_street_type VARCHAR NULL,
    w_suite_number VARCHAR NULL,
    w_city VARCHAR NULL,
    w_county VARCHAR NULL,
    w_state VARCHAR NULL,
    w_zip VARCHAR NULL,
    w_country VARCHAR NULL,
    w_gmt_offset DECIMAL(5,2) NULL
);
