-- This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL
-- was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
-- Ported from FlowKit (https://github.com/Flowminder/FlowKit), flowdb/testdata/bin/generate_synthetic_data_sql.py.

CREATE OR REPLACE TABLE _chunk AS
SELECT id, datetime, duration, volume_upload + volume_download AS volume_total, volume_upload, volume_download,
       msisdn, location_id, imsi, imei, tac, NULL::INTEGER AS operator_code, NULL::INTEGER AS country_code
FROM (
    SELECT *, round(rnd('duration|' || k) * 260) AS duration,
           round(rnd('upload|' || k) * 100000) AS volume_upload, round(rnd('download|' || k) * 100000) AS volume_download
    FROM _events
)
ORDER BY datetime, id;
