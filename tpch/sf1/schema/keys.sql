ALTER TABLE tpch_sf1.region ADD PRIMARY KEY (r_regionkey);
ALTER TABLE tpch_sf1.nation ADD PRIMARY KEY (n_nationkey);
ALTER TABLE tpch_sf1.part ADD PRIMARY KEY (p_partkey);
ALTER TABLE tpch_sf1.supplier ADD PRIMARY KEY (s_suppkey);
ALTER TABLE tpch_sf1.partsupp ADD PRIMARY KEY (ps_partkey, ps_suppkey);
ALTER TABLE tpch_sf1.customer ADD PRIMARY KEY (c_custkey);
ALTER TABLE tpch_sf1.orders ADD PRIMARY KEY (o_orderkey);
ALTER TABLE tpch_sf1.lineitem ADD PRIMARY KEY (l_orderkey, l_linenumber);

ALTER TABLE tpch_sf1.nation ADD FOREIGN KEY (n_regionkey) REFERENCES tpch_sf1.region (r_regionkey);
ALTER TABLE tpch_sf1.supplier ADD FOREIGN KEY (s_nationkey) REFERENCES tpch_sf1.nation (n_nationkey);
ALTER TABLE tpch_sf1.customer ADD FOREIGN KEY (c_nationkey) REFERENCES tpch_sf1.nation (n_nationkey);
ALTER TABLE tpch_sf1.partsupp ADD FOREIGN KEY (ps_partkey) REFERENCES tpch_sf1.part (p_partkey);
ALTER TABLE tpch_sf1.partsupp ADD FOREIGN KEY (ps_suppkey) REFERENCES tpch_sf1.supplier (s_suppkey);
ALTER TABLE tpch_sf1.orders ADD FOREIGN KEY (o_custkey) REFERENCES tpch_sf1.customer (c_custkey);
ALTER TABLE tpch_sf1.lineitem ADD FOREIGN KEY (l_orderkey) REFERENCES tpch_sf1.orders (o_orderkey);
ALTER TABLE tpch_sf1.lineitem ADD FOREIGN KEY (l_partkey) REFERENCES tpch_sf1.part (p_partkey);
ALTER TABLE tpch_sf1.lineitem ADD FOREIGN KEY (l_suppkey) REFERENCES tpch_sf1.supplier (s_suppkey);
ALTER TABLE tpch_sf1.lineitem ADD FOREIGN KEY (l_partkey, l_suppkey) REFERENCES tpch_sf1.partsupp (ps_partkey, ps_suppkey);
