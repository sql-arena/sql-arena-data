-- Rows of the row groups of a table whose min/max statistics do not rule out every filter term
SELECT coalesce(sum(n), 0)
FROM (
    SELECT any_value(num_rows) AS n
    FROM row_groups
    WHERE tbl = '%%TABLE%%'
    GROUP BY file, rg
    HAVING %%KEEP%%
)
