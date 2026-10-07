CREATE TABLE telecomitalia.mi_to_provinces (
    time_interval TIMESTAMP NOT NULL,
    square_id INT NOT NULL,
    province VARCHAR NOT NULL,
    cell_to_province DOUBLE NULL,
    province_to_cell DOUBLE NULL
);
