/* FlowKit Q31: location_introversion
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "location_introversion", "start_date": "2016-01-01", "end_date": "2016-01-08", "aggregation_unit": "admin3", "direction": "both"} */
WITH unioned_table AS (
  SELECT
    l.datetime,
    l.id,
    l.location_id,
    l.subscriber,
    l.outgoing,
    sites.pcod
  FROM (
    SELECT
      flowkit_sf100.calls.datetime,
      flowkit_sf100.calls.id,
      flowkit_sf100.calls.location_id,
      flowkit_sf100.calls.msisdn AS subscriber,
      flowkit_sf100.calls.outgoing
    FROM flowkit_sf100.calls
    WHERE
      flowkit_sf100.calls.datetime >= '2016-01-01 00:00:00'
      AND flowkit_sf100.calls.datetime < '2016-01-08 00:00:00'
    UNION ALL
    SELECT
      flowkit_sf100.sms.datetime,
      flowkit_sf100.sms.id,
      flowkit_sf100.sms.location_id,
      flowkit_sf100.sms.msisdn AS subscriber,
      flowkit_sf100.sms.outgoing
    FROM flowkit_sf100.sms
    WHERE
      flowkit_sf100.sms.datetime >= '2016-01-01 00:00:00'
      AND flowkit_sf100.sms.datetime < '2016-01-08 00:00:00'
  ) AS l
  INNER JOIN (
    SELECT
      loc_table.id AS location_id,
      loc_table.date_of_first_service,
      loc_table.date_of_last_service,
      geom_table.admin3pcod AS pcod
    FROM flowkit_sf100.cells AS loc_table
    INNER JOIN flowkit_sf100.cell_region AS geom_table
      ON loc_table.id = geom_table.location_id
  ) AS sites
    ON l.location_id = sites.location_id
    AND (
      sites.date_of_first_service IS NULL
      OR CAST(l.datetime AS DATE) >= sites.date_of_first_service
    )
    AND (
      sites.date_of_last_service IS NULL
      OR CAST(l.datetime AS DATE) <= sites.date_of_last_service
    )
)
SELECT
  pcod,
  SUM(CAST(introverted AS INT)) / CAST(COUNT(*) AS DOUBLE) AS value
FROM (
  SELECT
    a.pcod AS pcod,
    a.pcod = b.pcod AS introverted,
    a.subscriber
  FROM unioned_table AS a
  INNER JOIN unioned_table AS b
    ON a.id = b.id AND a.outgoing <> b.outgoing
) AS _
GROUP BY
  pcod
HAVING
  COUNT(DISTINCT subscriber) > 15
ORDER BY
  pcod DESC NULLS FIRST;
