/* FlowKit Q08: aggregate_network_objects
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "aggregate_network_objects", "statistic": "avg", "aggregate_by": "day", "total_network_objects": {"query_kind": "total_network_objects", "start_date": "2016-01-01", "end_date": "2016-01-08", "total_by": "hour", "aggregation_unit": "admin3", "event_types": null, "subscriber_subset": null}} */
SELECT
  pcod,
  AVG(z.value) AS value,
  DATE_TRUNC('day', z.datetime) AS datetime
FROM (
  SELECT
    pcod,
    COUNT(*) AS value,
    datetime
  FROM (
    SELECT DISTINCT
      pcod,
      location_id,
      datetime
    FROM (
      SELECT
        pcod,
        location_id,
        DATE_TRUNC('hour', x.datetime) AS datetime
      FROM (
        SELECT
          l.datetime,
          l.location_id,
          sites.pcod
        FROM (
          SELECT
            flowkit_sf1.calls.datetime,
            flowkit_sf1.calls.location_id
          FROM flowkit_sf1.calls
          WHERE
            flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
            AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
          UNION ALL
          SELECT
            flowkit_sf1.sms.datetime,
            flowkit_sf1.sms.location_id
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
      ) AS x
    ) AS y
  ) AS _
  GROUP BY
    pcod,
    datetime
  ORDER BY
    pcod NULLS LAST,
    datetime NULLS LAST
) AS z
GROUP BY
  pcod,
  DATE_TRUNC('day', z.datetime)
ORDER BY
  pcod NULLS LAST,
  DATE_TRUNC('day', z.datetime) NULLS LAST;
