-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- A synthetic country on a 12 x 6 grid of districts: 8 provinces of 3 x 3 districts, each split into 3 x 3
-- municipalities. Municipalities get a heavy-tailed population weight, so a few hold most sites and subscribers.
CREATE OR REPLACE TEMP TABLE admin3_bounds AS
WITH grid AS (
    SELECT p, d, m,
           (p % 4) * 3 + (d % 3) AS dx, (p // 4) * 3 + (d // 3) AS dy, m % 3 AS mx, m // 3 AS my
    FROM range(8) t(p), range(9) u(d), range(9) v(m)
)
SELECT row_number() OVER (ORDER BY p, d, m) AS gid,
       printf('SYN.%d.%d.%d_1', p + 1, d + 1, m + 1) AS admin3pcod,
       printf('Municipality %d.%d.%d', p + 1, d + 1, m + 1) AS admin3name,
       printf('SYN.%d.%d_1', p + 1, d + 1) AS parent_pcod,
       80.0 + (dx * 3 + mx) * (8.0 / 36) AS lon_min,
       26.5 + (dy * 3 + my) * (4.0 / 18) AS lat_min,
       80.0 + (dx * 3 + mx + 1) * (8.0 / 36) AS lon_max,
       26.5 + (dy * 3 + my + 1) * (4.0 / 18) AS lat_max,
       least(pow(1 - rnd('population|' || p || '|' || d || '|' || m), -1 / 1.2), 1000) AS population_weight
FROM grid;

CREATE OR REPLACE TEMP TABLE admin2_bounds AS
SELECT row_number() OVER (ORDER BY parent_pcod) AS gid,
       parent_pcod AS admin2pcod,
       replace(replace(parent_pcod, 'SYN.', 'District '), '_1', '') AS admin2name,
       regexp_replace(parent_pcod, '\.\d+_1$', '_1') AS parent_pcod,
       min(lon_min) AS lon_min, min(lat_min) AS lat_min, max(lon_max) AS lon_max, max(lat_max) AS lat_max
FROM admin3_bounds GROUP BY parent_pcod;

CREATE OR REPLACE TEMP TABLE admin1_bounds AS
SELECT row_number() OVER (ORDER BY parent_pcod) AS gid,
       parent_pcod AS admin1pcod,
       replace(replace(parent_pcod, 'SYN.', 'Province '), '_1', '') AS admin1name,
       'SYN' AS parent_pcod,
       min(lon_min) AS lon_min, min(lat_min) AS lat_min, max(lon_max) AS lon_max, max(lat_max) AS lat_max
FROM admin2_bounds GROUP BY parent_pcod;

CREATE OR REPLACE MACRO box_wkt(x0, y0, x1, y1) AS
    format('POLYGON (({} {}, {} {}, {} {}, {} {}, {} {}))', x0, y0, x1, y0, x1, y1, x0, y1, x0, y0);

-- FlowKit's geography.admin<N> views: gid, pcode, name, parent pcode and the polygon (here as WKT)
CREATE OR REPLACE TABLE admin1 AS
SELECT gid, admin1pcod, admin1name, parent_pcod, box_wkt(lon_min, lat_min, lon_max, lat_max) AS geom
FROM admin1_bounds ORDER BY gid;
CREATE OR REPLACE TABLE admin2 AS
SELECT gid, admin2pcod, admin2name, parent_pcod, box_wkt(lon_min, lat_min, lon_max, lat_max) AS geom
FROM admin2_bounds ORDER BY gid;
CREATE OR REPLACE TABLE admin3 AS
SELECT gid, admin3pcod, admin3name, parent_pcod, box_wkt(lon_min, lat_min, lon_max, lat_max) AS geom
FROM admin3_bounds ORDER BY gid;

-- Cumulative population, to place sites in proportion to it
CREATE OR REPLACE TEMP TABLE admin3_cdf AS
SELECT admin3pcod, lon_min, lat_min, lon_max, lat_max,
       coalesce(sum(population_weight) OVER (ORDER BY gid ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)
           / sum(population_weight) OVER () AS cdf_lo,
       sum(population_weight) OVER (ORDER BY gid) / sum(population_weight) OVER () AS cdf_hi
FROM admin3_bounds;
