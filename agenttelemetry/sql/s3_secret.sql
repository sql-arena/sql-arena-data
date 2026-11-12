LOAD httpfs;
LOAD aws;
CREATE OR REPLACE SECRET s3tables (TYPE s3, PROVIDER credential_chain, REGION '%%REGION%%');
