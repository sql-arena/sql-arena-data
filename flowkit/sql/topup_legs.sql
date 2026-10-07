-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- Each subscriber tops up on a day with probability %%TOPUP_PROBABILITY%%; FlowKit's generator has no topups
CREATE OR REPLACE TEMP TABLE _legs AS
SELECT day, 'topup|' || day || '|' || sub AS k, NULL::BOOLEAN AS outgoing, sub, NULL::BIGINT AS counterpart
FROM range(%%FIRST_DAY%%, %%LAST_DAY%% + 1) d(day), subs
WHERE rnd('topup|' || day || '|' || sub) < %%TOPUP_PROBABILITY%%;
