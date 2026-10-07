-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

CREATE OR REPLACE TABLE _chunk AS
SELECT id, datetime, 'recharge' AS type, recharge_amount, 0::DECIMAL(12, 2) AS airtime_fee,
       CAST(recharge_amount * 0.1 AS DECIMAL(12, 2)) AS tax_and_fee, pre_event_balance,
       CAST(pre_event_balance + recharge_amount * 0.9 AS DECIMAL(12, 2)) AS post_event_balance,
       msisdn, location_id, imsi, imei, tac, NULL::INTEGER AS operator_code, NULL::INTEGER AS country_code
FROM (
    SELECT *, CAST(([1, 2, 5, 10, 20, 50])[pick('amount|' || k, 6)] AS DECIMAL(12, 2)) AS recharge_amount,
           CAST(round(rnd('balance|' || k) * 20, 2) AS DECIMAL(12, 2)) AS pre_event_balance
    FROM _events
)
ORDER BY datetime, id;
