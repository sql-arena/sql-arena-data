-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- Mobile data sessions on days %%FIRST_DAY%% to %%LAST_DAY%%, each by a random subscriber
CREATE OR REPLACE TEMP TABLE _legs AS
SELECT day, 'mds|' || day || '|' || n AS k, NULL::BOOLEAN AS outgoing,
       pick('mds_sub|' || day || '|' || n, %%SUBSCRIBERS%%) AS sub, NULL::BIGINT AS counterpart
FROM range(%%FIRST_DAY%%, %%LAST_DAY%% + 1) d(day), range(%%PER_DAY%%) t(n);
