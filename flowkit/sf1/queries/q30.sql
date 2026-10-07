/* FlowKit Q30: consecutive_trips_od_matrix
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "consecutive_trips_od_matrix", "start_date": "2016-01-01", "end_date": "2016-01-08", "aggregation_unit": "admin2", "event_types": null, "subscriber_subset": null} */
SELECT
  pcod_from,
  pcod_to,
  value
FROM (
  WITH located AS (
    SELECT
      subscriber,
      pcod,
      ROW_NUMBER() OVER (PARTITION BY subscriber ORDER BY time ASC NULLS LAST) AS rank
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
            AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
          UNION ALL
          SELECT
            flowkit_sf1.sms.datetime,
            flowkit_sf1.sms.location_id,
            flowkit_sf1.sms.msisdn AS subscriber
          FROM flowkit_sf1.sms
          WHERE
            flowkit_sf1.sms.datetime >= '2016-01-01 00:00:00'
            AND flowkit_sf1.sms.datetime < '2016-01-08 00:00:00'
        ) AS l
        INNER JOIN (
          SELECT
            loc_table.id AS location_id,
            loc_table.date_of_first_service,
            loc_table.date_of_last_service,
            geom_table.admin2pcod AS pcod
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
    ) AS _
  )
  SELECT
    pcod_from,
    pcod_to,
    COUNT(*) AS value
  FROM (
    SELECT
      subscriber,
      source.pcod AS pcod_from,
      sink.pcod AS pcod_to
    FROM located AS source
    INNER JOIN (
      SELECT
        subscriber,
        pcod,
        rank - 1 AS rank
      FROM located
    ) AS sink
      USING (subscriber, rank)
    GROUP BY
      subscriber,
      pcod_from,
      pcod_to
  ) AS joined
  GROUP BY
    pcod_from,
    pcod_to
  ORDER BY
    pcod_from NULLS LAST,
    pcod_to DESC NULLS FIRST
) AS agged
WHERE
  agged.value > 15;
