/* FlowKit Q01: spatial_aggregate
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "spatial_aggregate", "locations": {"query_kind": "daily_location", "date": "2016-01-01", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}} */
SELECT
  pcod,
  value
FROM (
  SELECT
    pcod,
    COUNT(*) AS value
  FROM (
    SELECT
      subscriber,
      pcod
    FROM (
      SELECT
        subscriber_locs.subscriber AS subscriber,
        pcod AS pcod,
        ROW_NUMBER() OVER (
          PARTITION BY subscriber_locs.subscriber
          ORDER BY subscriber_locs.subscriber NULLS LAST, time DESC NULLS FIRST
        ) AS _row_number
      FROM (
        SELECT
          subscriber,
          datetime AS time,
          pcod
        FROM (
          SELECT
            l.datetime,
            l.location_id,
            l.subscriber,
            sites.pcod
          FROM (
            SELECT
              flowkit_sf1.calls.datetime,
              flowkit_sf1.calls.location_id,
              flowkit_sf1.calls.msisdn AS subscriber
            FROM flowkit_sf1.calls
            WHERE
              flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
              AND flowkit_sf1.calls.datetime < '2016-01-02 00:00:00'
            UNION ALL
            SELECT
              flowkit_sf1.sms.datetime,
              flowkit_sf1.sms.location_id,
              flowkit_sf1.sms.msisdn AS subscriber
            FROM flowkit_sf1.sms
            WHERE
              flowkit_sf1.sms.datetime >= '2016-01-01 00:00:00'
              AND flowkit_sf1.sms.datetime < '2016-01-02 00:00:00'
          ) AS l
          INNER JOIN (
            SELECT
              loc_table.id AS location_id,
              loc_table.date_of_first_service,
              loc_table.date_of_last_service,
              geom_table.admin3pcod AS pcod
            FROM flowkit_sf1.cells AS loc_table
            INNER JOIN flowkit_sf1.cell_region AS geom_table
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
        ) AS foo
        WHERE
          location_id IS NOT NULL AND location_id <> ''
      ) AS subscriber_locs
    ) AS _t
    WHERE
      _row_number = 1
  ) AS to_agg
  GROUP BY
    pcod
) AS agged
WHERE
  agged.value > 15;
