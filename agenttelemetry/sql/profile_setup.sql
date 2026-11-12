CREATE SCHEMA %%NS%%;
CREATE VIEW %%NS%%.spans AS SELECT * FROM read_parquet('%%ROOT%%/spans/*.parquet');
CREATE VIEW %%NS%%.traces AS SELECT * FROM read_parquet('%%ROOT%%/traces/*.parquet');
CREATE VIEW %%NS%%.scores AS SELECT * FROM read_parquet('%%ROOT%%/scores/*.parquet');
CREATE VIEW %%NS%%.tenants AS SELECT * FROM read_parquet('%%ROOT%%/tenants/*.parquet');
CREATE VIEW %%NS%%.model_prices AS SELECT * FROM read_parquet('%%ROOT%%/model_prices/*.parquet');
