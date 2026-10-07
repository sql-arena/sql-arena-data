CREATE TABLE tpch_sf1.orders (
    o_orderkey BIGINT NOT NULL,
    o_custkey BIGINT NOT NULL,
    o_orderstatus VARCHAR NOT NULL,
    o_totalprice DECIMAL(15,2) NOT NULL,
    o_orderdate DATE NOT NULL,
    o_orderpriority VARCHAR NOT NULL,
    o_clerk VARCHAR NOT NULL,
    o_shippriority INT NOT NULL,
    o_comment VARCHAR NOT NULL
);
