CREATE TABLE tpch_sf1.part (
    p_partkey BIGINT NOT NULL,
    p_name VARCHAR NOT NULL,
    p_mfgr VARCHAR NOT NULL,
    p_brand VARCHAR NOT NULL,
    p_type VARCHAR NOT NULL,
    p_size INT NOT NULL,
    p_container VARCHAR NOT NULL,
    p_retailprice DECIMAL(15,2) NOT NULL,
    p_comment VARCHAR NOT NULL
);
