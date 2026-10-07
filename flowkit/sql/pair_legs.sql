-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- %%EVENT%% events (calls or sms) on days %%FIRST_DAY%% to %%LAST_DAY%%: each picks a caller/callee pair and
-- has two legs, outgoing for the caller and incoming for the callee
CREATE OR REPLACE TEMP TABLE _legs AS
WITH e AS (
    SELECT day, '%%EVENT%%|' || day || '|' || n AS k, pick('%%EVENT%%_pair|' || day || '|' || n, %%PAIRS%%) AS pair
    FROM range(%%FIRST_DAY%%, %%LAST_DAY%% + 1) d(day), range(%%PER_DAY%%) t(n)
)
SELECT e.day, e.k, leg.outgoing, leg.sub, leg.counterpart
FROM e JOIN interactions i USING (pair),
     LATERAL (VALUES (true, i.caller, i.callee), (false, i.callee, i.caller)) leg(outgoing, sub, counterpart);
