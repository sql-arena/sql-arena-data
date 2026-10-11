-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- Randomness is md5 of a salt and the row's key, so every run gives the same data.
SET TimeZone = 'UTC';
CREATE OR REPLACE MACRO rnd(k) AS md5_number_lower(k)::DOUBLE / 18446744073709551616.0;
CREATE OR REPLACE MACRO pick(k, n) AS 1 + floor(rnd(k) * n)::BIGINT;

-- Share of a day's events in each hour: quiet nights, busy afternoons and evenings
SET VARIABLE hour_shares = (SELECT list_transform(%%HOUR_WEIGHTS%%, w -> w / list_sum(%%HOUR_WEIGHTS%%)));

-- An event of slot (day d, hour h): a uniform second within that hour
CREATE OR REPLACE MACRO event_time(d, h, k) AS
    (TIMESTAMP '2016-01-01' + to_days(d::INTEGER) + to_seconds(h * 3600 + floor(rnd('second|' || k) * 3600)::BIGINT))::TIMESTAMPTZ;

-- The events of hourly slots %%FIRST_SLOT%% to %%LAST_SLOT%% (slot = day * 24 + hour), each hour getting its share of
-- %%PER_DAY%% events a day
CREATE OR REPLACE MACRO slot_events(first_slot, last_slot, per_day) AS TABLE
    SELECT day, hour, unnest(range(round(per_day * getvariable('hour_shares')[hour + 1])::BIGINT)) AS n
    FROM (SELECT s // 24 AS day, s % 24 AS hour FROM range(first_slot, last_slot + 1) t(s));
