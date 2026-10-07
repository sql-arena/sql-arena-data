/* FlowKit Q24: histogram_aggregate
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "histogram_aggregate", "metric": {"query_kind": "radius_of_gyration", "start_date": "2016-01-01", "end_date": "2016-01-08", "event_types": null, "subscriber_subset": null}, "bins": {"n_bins": 20}} */
WITH bounds AS (
  SELECT
    CAST(MAX(value) AS DECIMAL) AS upper,
    CAST(MIN(value) AS DECIMAL) AS lower
  FROM (
    SELECT
      subscriber,
      SQRT(
        AVG(
          POWER(
            2 * 6371008.8 * ASIN(
              SQRT(
                POWER(SIN(RADIANS(av_lat - lat) / 2), 2) + COS(RADIANS(lat)) * COS(RADIANS(av_lat)) * POWER(SIN(RADIANS(av_lon - lon) / 2), 2)
              )
            ),
            2
          )
        )
      ) / 1000 AS value
    FROM (
      SELECT
        subscriber_locs.subscriber AS subscriber,
        lon,
        lat,
        AVG(lon) OVER (PARTITION BY subscriber_locs.subscriber) AS av_lon,
        AVG(lat) OVER (PARTITION BY subscriber_locs.subscriber) AS av_lat
      FROM (
        SELECT
          subscriber,
          datetime AS time,
          lon,
          lat
        FROM (
          SELECT
            l.datetime,
            l.location_id,
            l.subscriber,
            sites.lon,
            sites.lat
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
              loc_table.longitude AS lon,
              loc_table.latitude AS lat
            FROM flowkit_sf1.cells AS loc_table
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
          NOT location_id IS NULL AND location_id <> ''
      ) AS subscriber_locs
    ) AS located
    GROUP BY
      subscriber
  ) AS to_agg
), breaks AS (
  SELECT
    lower,
    upper,
    v
  FROM (
    SELECT
      v,
      (
        SELECT
          lower
        FROM bounds
      ) + (
        (
          v - 1
        ) * (
          SELECT
            (
              upper - lower
            ) / 20
          FROM bounds
        )
      ) AS lower,
      (
        SELECT
          lower
        FROM bounds
      ) + (
        v * (
          SELECT
            (
              upper - lower
            ) / 20
          FROM bounds
        )
      ) AS upper
    FROM (VALUES
      (1),
      (2),
      (3),
      (4),
      (5),
      (6),
      (7),
      (8),
      (9),
      (10),
      (11),
      (12),
      (13),
      (14),
      (15),
      (16),
      (17),
      (18),
      (19),
      (20)) AS v(v)
  ) AS b
), hist AS (
  SELECT
    COUNT(*) AS value,
    breaks.lower AS lower_edge,
    breaks.upper AS upper_edge
  FROM breaks
  LEFT JOIN (
    SELECT
      subscriber,
      SQRT(
        AVG(
          POWER(
            2 * 6371008.8 * ASIN(
              SQRT(
                POWER(SIN(RADIANS(av_lat - lat) / 2), 2) + COS(RADIANS(lat)) * COS(RADIANS(av_lat)) * POWER(SIN(RADIANS(av_lon - lon) / 2), 2)
              )
            ),
            2
          )
        )
      ) / 1000 AS value
    FROM (
      SELECT
        subscriber_locs.subscriber AS subscriber,
        lon,
        lat,
        AVG(lon) OVER (PARTITION BY subscriber_locs.subscriber) AS av_lon,
        AVG(lat) OVER (PARTITION BY subscriber_locs.subscriber) AS av_lat
      FROM (
        SELECT
          subscriber,
          datetime AS time,
          lon,
          lat
        FROM (
          SELECT
            l.datetime,
            l.location_id,
            l.subscriber,
            sites.lon,
            sites.lat
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
              loc_table.longitude AS lon,
              loc_table.latitude AS lat
            FROM flowkit_sf1.cells AS loc_table
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
          NOT location_id IS NULL AND location_id <> ''
      ) AS subscriber_locs
    ) AS located
    GROUP BY
      subscriber
  ) AS to_agg
    ON (
      CAST(to_agg.value AS DECIMAL) >= breaks.lower
      AND (
        CAST(to_agg.value AS DECIMAL) < breaks.upper
        OR (
          breaks.v = 20 AND CAST(to_agg.value AS DECIMAL) <= breaks.upper
        )
      )
    )
  GROUP BY
    breaks.lower,
    breaks.upper,
    breaks.v
  ORDER BY
    breaks.lower NULLS LAST
)
SELECT
  *
FROM (
  SELECT
    CASE WHEN (
      SELECT
        MIN(value) < 15
      FROM hist
    ) THEN NULL ELSE value END AS value,
    CASE WHEN (
      SELECT
        MIN(value) < 15
      FROM hist
    ) THEN NULL ELSE lower_edge END AS lower_edge,
    CASE WHEN (
      SELECT
        MIN(value) < 15
      FROM hist
    ) THEN NULL ELSE upper_edge END AS upper_edge
  FROM hist
) AS _
GROUP BY
  lower_edge,
  upper_edge,
  value
ORDER BY
  lower_edge ASC NULLS LAST;
