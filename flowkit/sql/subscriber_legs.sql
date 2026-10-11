-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- %%EVENT%% events (mds or topups), each by a random subscriber
CREATE OR REPLACE TEMP TABLE _legs AS
SELECT day, hour, k, NULL::BOOLEAN AS outgoing, pick('%%EVENT%%_sub|' || k, %%SUBSCRIBERS%%) AS sub,
       NULL::BIGINT AS counterpart
FROM (
    SELECT day, hour, '%%EVENT%%|' || day || '|' || hour || '|' || n AS k
    FROM slot_events(%%FIRST_SLOT%%, %%LAST_SLOT%%, %%PER_DAY%%)
);
