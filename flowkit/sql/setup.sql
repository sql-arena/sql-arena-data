-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

-- Randomness is md5 of a salt and the row's key, so every run gives the same data.
SET TimeZone = 'UTC';
CREATE OR REPLACE MACRO rnd(k) AS md5_number_lower(k)::DOUBLE / 18446744073709551616.0;
CREATE OR REPLACE MACRO pick(k, n) AS 1 + floor(rnd(k) * n)::BIGINT;

-- Share of events per hour of day: quiet nights, busy afternoons and evenings
SET VARIABLE hour_cdf = (
    WITH w AS (
        SELECT unnest(range(24)) AS hour,
               unnest([1.0, 0.6, 0.4, 0.3, 0.3, 0.5, 1.2, 2.5, 4.0, 5.0, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 6.0, 6.0,
                       5.5, 5.0, 4.0, 3.0, 2.0]) AS weight
    )
    SELECT list(c ORDER BY hour) FROM (SELECT hour, sum(weight) OVER (ORDER BY hour) / sum(weight) OVER () AS c FROM w)
);

-- A time on day d (days after 2016-01-01): the hour follows the profile, the second within it is uniform
CREATE OR REPLACE MACRO event_time(d, k) AS
    (TIMESTAMP '2016-01-01' + to_days(d::INTEGER)
     + to_seconds(len(list_filter(getvariable('hour_cdf'), c -> c <= rnd('hour|' || k))) * 3600
                  + floor(rnd('second|' || k) * 3600)::BIGINT))::TIMESTAMPTZ;
