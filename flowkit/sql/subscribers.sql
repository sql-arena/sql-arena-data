-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

CREATE OR REPLACE TEMP TABLE subs AS
SELECT range + 1 AS sub,
       md5('msisdn|' || (range + 1)) AS msisdn,
       md5('imei|' || (range + 1)) AS imei,
       md5('imsi|' || (range + 1)) AS imsi,
       pick('tac|' || (range + 1), %%TACS%%) AS tac
FROM range(%%SUBSCRIBERS%%);

-- A home cell from day 0, and a new one on each day a subscriber relocates. Cells are placed by population,
-- so a uniform pick over cells puts homes where people live, as in FlowKit.
CREATE OR REPLACE TEMP TABLE homes AS
SELECT sub, 0 AS from_day, pick('home|' || sub || '|0', %%CELLS%%) AS home_cell FROM subs
UNION ALL
SELECT sub, day, pick('home|' || sub || '|' || day, %%CELLS%%)
FROM subs, range(1, %%DAYS%%) t(day)
WHERE rnd('relocate|' || sub || '|' || day) < %%RELOCATION%%;

-- Calls and SMS pick one of these caller/callee pairs, which gives everyone a set of contacts
CREATE OR REPLACE TEMP TABLE interactions AS
SELECT range + 1 AS pair,
       pick('caller|' || (range + 1), %%SUBSCRIBERS%%) AS caller,
       pick('callee|' || (range + 1), %%SUBSCRIBERS%%) AS callee
FROM range(%%SUBSCRIBERS%% * %%INTERACTIONS%%);
