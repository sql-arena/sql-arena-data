-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- Places each leg at a cell within 3 km of the subscriber's home that day, or with probability %%OUT_OF_AREA%%
-- at any cell, and adds the subscriber's identifiers
CREATE OR REPLACE TEMP TABLE _events AS
WITH homed AS (
    SELECT l.*, h.home_cell AS home, coalesce(l.outgoing::VARCHAR, '') || '|' || l.k AS lk
    FROM _legs l ASOF JOIN homes h ON l.sub = h.sub AND l.day >= h.from_day
),
drawn AS (
    SELECT *, rnd('away|' || lk) < %%OUT_OF_AREA%% AS away, rnd('near|' || lk) AS near FROM homed
)
SELECT d.k, d.outgoing, md5(d.k) AS id, event_time(d.day, d.k) AS datetime,
       s.msisdn, c.msisdn AS msisdn_counterpart,
       md5('cell|' || CASE WHEN d.away THEN pick('anywhere|' || d.lk, %%CELLS%%) ELSE nb.neighbour END) AS location_id,
       s.imsi, s.imei, s.tac
FROM drawn d
JOIN subs s ON s.sub = d.sub
LEFT JOIN subs c ON c.sub = d.counterpart
JOIN neighbour_counts nc ON nc.cell_id = d.home
LEFT JOIN neighbours nb ON nb.cell_id = d.home AND nb.k = 1 + floor(d.near * nc.n)::BIGINT AND NOT d.away;
