CREATE TABLE tpcds_sf1000.web_page (
    wp_web_page_sk BIGINT NOT NULL,
    wp_web_page_id VARCHAR NOT NULL,
    wp_rec_start_date DATE NULL,
    wp_rec_end_date DATE NULL,
    wp_creation_date_sk BIGINT NULL,
    wp_access_date_sk BIGINT NULL,
    wp_autogen_flag VARCHAR NULL,
    wp_customer_sk BIGINT NULL,
    wp_url VARCHAR NULL,
    wp_type VARCHAR NULL,
    wp_char_count BIGINT NULL,
    wp_link_count BIGINT NULL,
    wp_image_count BIGINT NULL,
    wp_max_ad_count INT NULL
);
