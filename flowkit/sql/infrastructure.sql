-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

CREATE OR REPLACE TEMP TABLE site_gen AS
WITH s AS (SELECT range + 1 AS site_id, rnd('site|' || (range + 1)) AS u FROM range(%%SITES%%))
SELECT s.site_id,
       md5('site|' || s.site_id) AS id,
       0 AS version,
       DATE '2015-01-01' + floor(rnd('site_service|' || s.site_id) * 365)::INTEGER AS date_of_first_service,
       a.admin3pcod,
       a.lon_min + rnd('site_lon|' || s.site_id) * (a.lon_max - a.lon_min) AS longitude,
       a.lat_min + rnd('site_lat|' || s.site_id) * (a.lat_max - a.lat_min) AS latitude
FROM s JOIN admin3_cdf a ON s.u >= a.cdf_lo AND s.u < a.cdf_hi;

-- One cell per site, the rest on random sites; a cell sits at its site
CREATE OR REPLACE TEMP TABLE cell_gen AS
WITH c AS (
    SELECT range + 1 AS cell_id,
           CASE WHEN range < %%SITES%% THEN range + 1 ELSE pick('cell_site|' || (range + 1), %%SITES%%) END AS site
    FROM range(%%CELLS%%)
)
SELECT c.cell_id, md5('cell|' || c.cell_id) AS id, 0 AS version, s.id AS site_id,
       s.date_of_first_service, s.admin3pcod, s.longitude, s.latitude
FROM c JOIN site_gen s ON s.site_id = c.site
ORDER BY c.cell_id;

CREATE OR REPLACE TABLE tacs AS
SELECT range + 1 AS id,
       (['Nokia', 'Huawei', 'Apple', 'Samsung', 'Sony', 'LG', 'Google', 'Xiaomi', 'ZTE'])[pick('tac_brand|' || (range + 1), 9)] AS brand,
       md5('tac_model|' || (range + 1)) AS model,
       (['Smart', 'Feature', 'Basic'])[pick('tac_type|' || (range + 1), 3)] AS hnd_type
FROM range(%%TACS%%);

-- FlowKit's infrastructure tables, keeping the columns its generator fills; geometry as WKT plus lon/lat
CREATE OR REPLACE TABLE sites AS
SELECT site_id, id, version, date_of_first_service, NULL::DATE AS date_of_last_service,
       format('POINT ({} {})', longitude, latitude) AS geom_point, longitude, latitude
FROM site_gen ORDER BY site_id;
CREATE OR REPLACE TABLE cells AS
SELECT cell_id, id, version, site_id, date_of_first_service, NULL::DATE AS date_of_last_service,
       format('POINT ({} {})', longitude, latitude) AS geom_point, longitude, latitude
FROM cell_gen ORDER BY cell_id;

-- Replaces FlowKit's st_within joins from cell points to admin polygons
CREATE OR REPLACE TABLE cell_region AS
SELECT c.id AS location_id, a3.admin3pcod, a3.parent_pcod AS admin2pcod, a2.parent_pcod AS admin1pcod
FROM cell_gen c JOIN admin3 a3 USING (admin3pcod) JOIN admin2 a2 ON a2.admin2pcod = a3.parent_pcod
ORDER BY c.id;

-- Cells within 3 km of each cell (itself included), numbered so an event can pick one; FlowKit uses st_dwithin
CREATE OR REPLACE TEMP TABLE neighbours AS
WITH b AS (SELECT cell_id, longitude, latitude, floor(longitude / 0.05) AS bx, floor(latitude / 0.05) AS by FROM cell_gen)
SELECT a.cell_id, row_number() OVER (PARTITION BY a.cell_id ORDER BY n.cell_id) AS k, n.cell_id AS neighbour
FROM b a JOIN b n ON n.bx BETWEEN a.bx - 1 AND a.bx + 1 AND n.by BETWEEN a.by - 1 AND a.by + 1
WHERE 6371000 * 2 * asin(sqrt(
          pow(sin(radians(n.latitude - a.latitude) / 2), 2)
          + cos(radians(a.latitude)) * cos(radians(n.latitude)) * pow(sin(radians(n.longitude - a.longitude) / 2), 2)
      )) <= 3000;

CREATE OR REPLACE TEMP TABLE neighbour_counts AS
SELECT cell_id, max(k) AS n FROM neighbours GROUP BY cell_id;
