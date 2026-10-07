CREATE TABLE flowkit_sf1.cells (
    cell_id BIGINT NOT NULL,
    id VARCHAR NOT NULL,
    version INT NOT NULL,
    site_id VARCHAR NOT NULL,
    date_of_first_service DATE NOT NULL,
    date_of_last_service DATE NULL,
    geom_point VARCHAR NOT NULL,
    longitude DOUBLE NOT NULL,
    latitude DOUBLE NOT NULL
);
