CREATE TABLE tpcds_sf1000.time_dim (
    t_time_sk BIGINT NOT NULL,
    t_time_id VARCHAR NOT NULL,
    t_time BIGINT NULL,
    t_hour BIGINT NULL,
    t_minute BIGINT NULL,
    t_second BIGINT NULL,
    t_am_pm VARCHAR NULL,
    t_shift VARCHAR NULL,
    t_sub_shift VARCHAR NULL,
    t_meal_time VARCHAR NULL
);
