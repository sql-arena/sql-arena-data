CREATE TABLE flowkit_sf1.sites (
    site_id BIGINT NOT NULL,
    id VARCHAR NOT NULL,
    version INT NOT NULL,
    date_of_first_service DATE NOT NULL,
    date_of_last_service DATE NULL,
    geom_point VARCHAR NOT NULL,
    longitude DOUBLE NOT NULL,
    latitude DOUBLE NOT NULL
);
