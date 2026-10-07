/* FlowKit Q19: joined_spatial_aggregate
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "joined_spatial_aggregate", "method": "distr", "locations": {"query_kind": "modal_location", "locations": [{"query_kind": "daily_location", "date": "2016-01-01", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-02", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-03", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-04", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-05", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-06", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-07", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}]}, "metric": {"query_kind": "handset", "start_date": "2016-01-01", "end_date": "2016-01-08", "event_types": null, "subscriber_subset": null, "characteristic": "hnd_type", "method": "most-common"}} */
SELECT
  jsa.*
FROM (
  WITH joined AS (
    SELECT
      metric.subscriber,
      metric.value,
      location.pcod
    FROM (
      SELECT
        subscriber,
        value
      FROM (
        SELECT
          t.subscriber AS subscriber,
          t.hnd_type AS value,
          ROW_NUMBER() OVER (PARTITION BY t.subscriber ORDER BY COUNT(*) DESC, t.hnd_type) AS mode_rank
        FROM (
          SELECT
            t1.tac,
            t1.subscriber AS subscriber,
            t1.time AS time,
            t2.brand AS brand,
            t2.model AS model,
            t2.hnd_type AS hnd_type
          FROM (
            SELECT
              subscriber,
              datetime AS time,
              tac
            FROM (
              SELECT
                flowkit_sf1.calls.datetime,
                flowkit_sf1.calls.msisdn AS subscriber,
                flowkit_sf1.calls.tac
              FROM flowkit_sf1.calls
              WHERE
                flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
                AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
              UNION ALL
              SELECT
                flowkit_sf1.sms.datetime,
                flowkit_sf1.sms.msisdn AS subscriber,
                flowkit_sf1.sms.tac
              FROM flowkit_sf1.sms
              WHERE
                flowkit_sf1.sms.datetime >= '2016-01-01 00:00:00'
                AND flowkit_sf1.sms.datetime < '2016-01-08 00:00:00'
            ) AS e
            WHERE
              NOT tac IS NULL
            ORDER BY
              datetime NULLS LAST
          ) AS t1
          LEFT JOIN (
            SELECT
              id,
              brand,
              model,
              hnd_type
            FROM flowkit_sf1.tacs
          ) AS t2
            ON t1.tac = t2.id
        ) AS t
        GROUP BY
          t.subscriber,
          t.hnd_type
      ) AS modal
      WHERE
        mode_rank = 1
    ) AS metric
    INNER JOIN (
      SELECT
        ranked.subscriber,
        pcod
      FROM (
        SELECT
          times_visited.subscriber,
          pcod,
          ROW_NUMBER() OVER (
            PARTITION BY times_visited.subscriber
            ORDER BY total DESC NULLS FIRST, times_visited.date DESC NULLS FIRST
          ) AS rank
        FROM (
          SELECT
            all_locs.subscriber,
            pcod,
            COUNT(*) AS total,
            MAX(all_locs.date) AS date
          FROM (
            (
              (
                (
                  (
                    (
                      SELECT
                        *,
                        CAST('2016-01-01T00:00:00' AS TIMESTAMP) AS date
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
                      ) AS _
                      UNION ALL
                      SELECT
                        *,
                        CAST('2016-01-02T00:00:00' AS TIMESTAMP) AS date
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
                                  flowkit_sf1.calls.datetime >= '2016-01-02 00:00:00'
                                  AND flowkit_sf1.calls.datetime < '2016-01-03 00:00:00'
                                UNION ALL
                                SELECT
                                  flowkit_sf1.sms.datetime,
                                  flowkit_sf1.sms.location_id,
                                  flowkit_sf1.sms.msisdn AS subscriber
                                FROM flowkit_sf1.sms
                                WHERE
                                  flowkit_sf1.sms.datetime >= '2016-01-02 00:00:00'
                                  AND flowkit_sf1.sms.datetime < '2016-01-03 00:00:00'
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
                      ) AS _
                    )
                    UNION ALL
                    SELECT
                      *,
                      CAST('2016-01-03T00:00:00' AS TIMESTAMP) AS date
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
                                flowkit_sf1.calls.datetime >= '2016-01-03 00:00:00'
                                AND flowkit_sf1.calls.datetime < '2016-01-04 00:00:00'
                              UNION ALL
                              SELECT
                                flowkit_sf1.sms.datetime,
                                flowkit_sf1.sms.location_id,
                                flowkit_sf1.sms.msisdn AS subscriber
                              FROM flowkit_sf1.sms
                              WHERE
                                flowkit_sf1.sms.datetime >= '2016-01-03 00:00:00'
                                AND flowkit_sf1.sms.datetime < '2016-01-04 00:00:00'
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
                    ) AS _
                  )
                  UNION ALL
                  SELECT
                    *,
                    CAST('2016-01-04T00:00:00' AS TIMESTAMP) AS date
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
                              flowkit_sf1.calls.datetime >= '2016-01-04 00:00:00'
                              AND flowkit_sf1.calls.datetime < '2016-01-05 00:00:00'
                            UNION ALL
                            SELECT
                              flowkit_sf1.sms.datetime,
                              flowkit_sf1.sms.location_id,
                              flowkit_sf1.sms.msisdn AS subscriber
                            FROM flowkit_sf1.sms
                            WHERE
                              flowkit_sf1.sms.datetime >= '2016-01-04 00:00:00'
                              AND flowkit_sf1.sms.datetime < '2016-01-05 00:00:00'
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
                  ) AS _
                )
                UNION ALL
                SELECT
                  *,
                  CAST('2016-01-05T00:00:00' AS TIMESTAMP) AS date
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
                            flowkit_sf1.calls.datetime >= '2016-01-05 00:00:00'
                            AND flowkit_sf1.calls.datetime < '2016-01-06 00:00:00'
                          UNION ALL
                          SELECT
                            flowkit_sf1.sms.datetime,
                            flowkit_sf1.sms.location_id,
                            flowkit_sf1.sms.msisdn AS subscriber
                          FROM flowkit_sf1.sms
                          WHERE
                            flowkit_sf1.sms.datetime >= '2016-01-05 00:00:00'
                            AND flowkit_sf1.sms.datetime < '2016-01-06 00:00:00'
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
                ) AS _
              )
              UNION ALL
              SELECT
                *,
                CAST('2016-01-06T00:00:00' AS TIMESTAMP) AS date
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
                          flowkit_sf1.calls.datetime >= '2016-01-06 00:00:00'
                          AND flowkit_sf1.calls.datetime < '2016-01-07 00:00:00'
                        UNION ALL
                        SELECT
                          flowkit_sf1.sms.datetime,
                          flowkit_sf1.sms.location_id,
                          flowkit_sf1.sms.msisdn AS subscriber
                        FROM flowkit_sf1.sms
                        WHERE
                          flowkit_sf1.sms.datetime >= '2016-01-06 00:00:00'
                          AND flowkit_sf1.sms.datetime < '2016-01-07 00:00:00'
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
              ) AS _
            )
            UNION ALL
            SELECT
              *,
              CAST('2016-01-07T00:00:00' AS TIMESTAMP) AS date
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
                        flowkit_sf1.calls.datetime >= '2016-01-07 00:00:00'
                        AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
                      UNION ALL
                      SELECT
                        flowkit_sf1.sms.datetime,
                        flowkit_sf1.sms.location_id,
                        flowkit_sf1.sms.msisdn AS subscriber
                      FROM flowkit_sf1.sms
                      WHERE
                        flowkit_sf1.sms.datetime >= '2016-01-07 00:00:00'
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
                  ) AS foo
                  WHERE
                    location_id IS NOT NULL AND location_id <> ''
                ) AS subscriber_locs
              ) AS _t
              WHERE
                _row_number = 1
            ) AS _
          ) AS all_locs
          GROUP BY
            all_locs.subscriber,
            pcod
        ) AS times_visited
      ) AS ranked
      WHERE
        rank = 1
    ) AS location
      ON metric.subscriber = location.subscriber
  )
  SELECT
    pcod,
    'value' AS metric,
    key,
    value / SUM(value) OVER (PARTITION BY pcod) AS value
  FROM (
    SELECT
      pcod,
      CAST(value AS TEXT) AS key,
      COUNT(*) AS value
    FROM joined
    GROUP BY
      pcod,
      value
  ) AS _
) AS jsa
INNER JOIN (
  SELECT
    pcod,
    value
  FROM (
    SELECT
      pcod,
      COUNT(*) AS value
    FROM (
      SELECT
        ranked.subscriber,
        pcod
      FROM (
        SELECT
          times_visited.subscriber,
          pcod,
          ROW_NUMBER() OVER (
            PARTITION BY times_visited.subscriber
            ORDER BY total DESC NULLS FIRST, times_visited.date DESC NULLS FIRST
          ) AS rank
        FROM (
          SELECT
            all_locs.subscriber,
            pcod,
            COUNT(*) AS total,
            MAX(all_locs.date) AS date
          FROM (
            (
              (
                (
                  (
                    (
                      SELECT
                        *,
                        CAST('2016-01-01T00:00:00' AS TIMESTAMP) AS date
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
                      ) AS _
                      UNION ALL
                      SELECT
                        *,
                        CAST('2016-01-02T00:00:00' AS TIMESTAMP) AS date
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
                                  flowkit_sf1.calls.datetime >= '2016-01-02 00:00:00'
                                  AND flowkit_sf1.calls.datetime < '2016-01-03 00:00:00'
                                UNION ALL
                                SELECT
                                  flowkit_sf1.sms.datetime,
                                  flowkit_sf1.sms.location_id,
                                  flowkit_sf1.sms.msisdn AS subscriber
                                FROM flowkit_sf1.sms
                                WHERE
                                  flowkit_sf1.sms.datetime >= '2016-01-02 00:00:00'
                                  AND flowkit_sf1.sms.datetime < '2016-01-03 00:00:00'
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
                      ) AS _
                    )
                    UNION ALL
                    SELECT
                      *,
                      CAST('2016-01-03T00:00:00' AS TIMESTAMP) AS date
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
                                flowkit_sf1.calls.datetime >= '2016-01-03 00:00:00'
                                AND flowkit_sf1.calls.datetime < '2016-01-04 00:00:00'
                              UNION ALL
                              SELECT
                                flowkit_sf1.sms.datetime,
                                flowkit_sf1.sms.location_id,
                                flowkit_sf1.sms.msisdn AS subscriber
                              FROM flowkit_sf1.sms
                              WHERE
                                flowkit_sf1.sms.datetime >= '2016-01-03 00:00:00'
                                AND flowkit_sf1.sms.datetime < '2016-01-04 00:00:00'
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
                    ) AS _
                  )
                  UNION ALL
                  SELECT
                    *,
                    CAST('2016-01-04T00:00:00' AS TIMESTAMP) AS date
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
                              flowkit_sf1.calls.datetime >= '2016-01-04 00:00:00'
                              AND flowkit_sf1.calls.datetime < '2016-01-05 00:00:00'
                            UNION ALL
                            SELECT
                              flowkit_sf1.sms.datetime,
                              flowkit_sf1.sms.location_id,
                              flowkit_sf1.sms.msisdn AS subscriber
                            FROM flowkit_sf1.sms
                            WHERE
                              flowkit_sf1.sms.datetime >= '2016-01-04 00:00:00'
                              AND flowkit_sf1.sms.datetime < '2016-01-05 00:00:00'
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
                  ) AS _
                )
                UNION ALL
                SELECT
                  *,
                  CAST('2016-01-05T00:00:00' AS TIMESTAMP) AS date
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
                            flowkit_sf1.calls.datetime >= '2016-01-05 00:00:00'
                            AND flowkit_sf1.calls.datetime < '2016-01-06 00:00:00'
                          UNION ALL
                          SELECT
                            flowkit_sf1.sms.datetime,
                            flowkit_sf1.sms.location_id,
                            flowkit_sf1.sms.msisdn AS subscriber
                          FROM flowkit_sf1.sms
                          WHERE
                            flowkit_sf1.sms.datetime >= '2016-01-05 00:00:00'
                            AND flowkit_sf1.sms.datetime < '2016-01-06 00:00:00'
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
                ) AS _
              )
              UNION ALL
              SELECT
                *,
                CAST('2016-01-06T00:00:00' AS TIMESTAMP) AS date
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
                          flowkit_sf1.calls.datetime >= '2016-01-06 00:00:00'
                          AND flowkit_sf1.calls.datetime < '2016-01-07 00:00:00'
                        UNION ALL
                        SELECT
                          flowkit_sf1.sms.datetime,
                          flowkit_sf1.sms.location_id,
                          flowkit_sf1.sms.msisdn AS subscriber
                        FROM flowkit_sf1.sms
                        WHERE
                          flowkit_sf1.sms.datetime >= '2016-01-06 00:00:00'
                          AND flowkit_sf1.sms.datetime < '2016-01-07 00:00:00'
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
              ) AS _
            )
            UNION ALL
            SELECT
              *,
              CAST('2016-01-07T00:00:00' AS TIMESTAMP) AS date
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
                        flowkit_sf1.calls.datetime >= '2016-01-07 00:00:00'
                        AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
                      UNION ALL
                      SELECT
                        flowkit_sf1.sms.datetime,
                        flowkit_sf1.sms.location_id,
                        flowkit_sf1.sms.msisdn AS subscriber
                      FROM flowkit_sf1.sms
                      WHERE
                        flowkit_sf1.sms.datetime >= '2016-01-07 00:00:00'
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
                  ) AS foo
                  WHERE
                    location_id IS NOT NULL AND location_id <> ''
                ) AS subscriber_locs
              ) AS _t
              WHERE
                _row_number = 1
            ) AS _
          ) AS all_locs
          GROUP BY
            all_locs.subscriber,
            pcod
        ) AS times_visited
      ) AS ranked
      WHERE
        rank = 1
    ) AS to_agg
    GROUP BY
      pcod
  ) AS agged
  WHERE
    agged.value > 15
) AS redact
  USING (pcod);
