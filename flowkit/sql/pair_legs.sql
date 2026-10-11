-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- %%EVENT%% events (calls or sms): each picks a caller/callee pair and has two legs, outgoing for the caller and
-- incoming for the callee
CREATE OR REPLACE TEMP TABLE _legs AS
WITH e AS (
    SELECT day, hour, '%%EVENT%%|' || day || '|' || hour || '|' || n AS k
    FROM slot_events(%%FIRST_SLOT%%, %%LAST_SLOT%%, %%PER_DAY%%)
)
SELECT e.day, e.hour, e.k, leg.outgoing, leg.sub, leg.counterpart
FROM e JOIN interactions i ON i.pair = pick('%%EVENT%%_pair|' || e.k, %%PAIRS%%),
     LATERAL (VALUES (true, i.caller, i.callee), (false, i.callee, i.caller)) leg(outgoing, sub, counterpart);
