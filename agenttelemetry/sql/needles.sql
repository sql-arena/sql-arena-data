-- Needles: values a query can look up, computed from a day d (0 is 2025-01-01) and a slot. The generator plants the
-- text ones and every scale factor has them all; the trace and session ones need no planting, as session n of a day
-- is the same at every scale factor and sessions 0 to 39 exist on every day.
CREATE OR REPLACE MACRO needle_session(d, n) AS md5('session|s|' || d || '|' || n);
CREATE OR REPLACE MACRO needle_trace(d, n, i) AS md5('trace|s|' || d || '|' || n || '|' || i);
-- Error codes 0 to 3 of day d, each in the output of one tool call and the input of the model call that reads it
CREATE OR REPLACE MACRO needle_code(d, k) AS 'ERR_' || upper(substr(md5('needle|code|' || d || '|' || k), 1, 12));
-- A place name with non-ASCII letters in one support task of day d; 7919 is prime to 12^3, so no two days share one
CREATE OR REPLACE MACRO needle_place(d) AS (
    SELECT ['Ær', 'Kø', 'Å', 'Zü', 'Ma', 'Tró', 'Łó', 'Pl', 'Bé', 'Rey', 'Dü', 'Sø'][1 + j // 144]
           || ['skø', 'lé', 'rö', 'dź', 'vå', 'nü', 'çe', 'þó', 'bè', 'gå', 'mø', 'ló'][1 + j // 12 % 12]
           || ['bing', 'ská', 'strand', 'ville', 'holm', 'dorf', 'fjörð', 'burg', 'sund', 'wice', 'ões', 'jökull'][1 + j % 12]
    FROM (SELECT (d * 7919) % 1728 AS j)
);
