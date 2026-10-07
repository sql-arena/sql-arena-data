-- dsdgen writes | separated fields without quoting; an empty field is NULL
COPY tpcds.%%TABLE%% FROM '%%PATH%%' (FORMAT CSV, DELIMITER '|', HEADER FALSE, QUOTE '', ESCAPE '', NULL '');
