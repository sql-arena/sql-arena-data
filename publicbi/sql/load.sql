-- Fields are separated by | and not quoted. A backslash escapes the next character, as in MonetDB's COPY INTO,
-- which the benchmark was built with. Escaped \\ and \| are swapped for control characters before splitting.
INSERT INTO "%%TABLE%%"
SELECT %%FIELDS%%
FROM (
    SELECT list_transform(
        string_split(replace(replace(line, '\\', chr(30)), '\|', chr(31)), '|'),
        x -> nullif(replace(replace(x, chr(31), '|'), chr(30), '\'), 'null')
    ) AS f
    FROM read_csv('%%PATH%%', columns = {'line': 'VARCHAR'}, delim = chr(1), quote = '', escape = '',
                  header = false, auto_detect = false, max_line_size = 100000000)
)
WHERE CASE WHEN len(f) <> %%COLUMN_COUNT%% THEN error('row has ' || len(f) || ' fields: ' || f::VARCHAR) ELSE true END;
