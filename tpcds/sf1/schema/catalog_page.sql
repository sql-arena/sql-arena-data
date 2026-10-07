CREATE TABLE tpcds_sf1.catalog_page (
    cp_catalog_page_sk BIGINT NOT NULL,
    cp_catalog_page_id VARCHAR NOT NULL,
    cp_start_date_sk BIGINT NULL,
    cp_end_date_sk BIGINT NULL,
    cp_department VARCHAR NULL,
    cp_catalog_number BIGINT NULL,
    cp_catalog_page_number BIGINT NULL,
    cp_description VARCHAR NULL,
    cp_type VARCHAR NULL
);
