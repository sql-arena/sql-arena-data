/* FlowKit Q18: joined_spatial_aggregate
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "joined_spatial_aggregate", "method": "avg", "locations": {"query_kind": "modal_location", "locations": [{"query_kind": "daily_location", "date": "2016-01-01", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-02", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-03", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-04", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-05", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-06", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}, {"query_kind": "daily_location", "date": "2016-01-07", "aggregation_unit": "admin3", "method": "last", "event_types": null, "subscriber_subset": null}]}, "metric": {"query_kind": "pareto_interactions", "start_date": "2016-01-01", "end_date": "2016-01-08", "event_types": null, "subscriber_subset": null, "proportion": 0.8}} */
SELECT
  jsa.*
FROM (
  SELECT
    pcod,
    AVG(value) AS value
  FROM (
    SELECT
      metric.subscriber,
      metric.value,
      location.pcod
    FROM (
      SELECT
        uc.subscriber AS subscriber,
        uc.n_contacts / CAST(ud.value AS DOUBLE) AS value
      FROM (
        SELECT
          n_contacts,
          subscriber,
          dif
        FROM (
          SELECT
            n_contacts AS n_contacts,
            cu.subscriber AS subscriber,
            tgt.target - cu.cum_events AS dif,
            ROW_NUMBER() OVER (
              PARTITION BY cu.subscriber
              ORDER BY cu.subscriber NULLS LAST, n_contacts NULLS LAST
            ) AS _row_number
          FROM (
            SELECT
              ROW_NUMBER() OVER (
                PARTITION BY c.subscriber
                ORDER BY events DESC NULLS FIRST, c.msisdn_counterpart DESC NULLS FIRST
              ) AS n_contacts,
              c.subscriber,
              c.msisdn_counterpart,
              c.events,
              SUM(c.events) OVER (
                PARTITION BY c.subscriber
                ORDER BY events DESC NULLS FIRST, c.msisdn_counterpart DESC NULLS FIRST
              ) AS cum_events
            FROM (
              WITH unioned AS (
                SELECT
                  *
                FROM (
                  SELECT
                    flowkit_sf1.calls.msisdn AS subscriber,
                    flowkit_sf1.calls.msisdn_counterpart
                  FROM flowkit_sf1.calls
                  WHERE
                    flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
                    AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
                  UNION ALL
                  SELECT
                    flowkit_sf1.sms.msisdn AS subscriber,
                    flowkit_sf1.sms.msisdn_counterpart
                  FROM flowkit_sf1.sms
                  WHERE
                    flowkit_sf1.sms.datetime >= '2016-01-01 00:00:00'
                    AND flowkit_sf1.sms.datetime < '2016-01-08 00:00:00'
                ) AS u
              ), total_events AS (
                SELECT
                  subscriber,
                  COUNT(*) AS events
                FROM unioned
                GROUP BY
                  subscriber
              )
              SELECT
                u.subscriber,
                u.msisdn_counterpart,
                COUNT(*) AS events,
                CAST(COUNT(*) AS DOUBLE) / CAST(t.events AS DOUBLE) AS proportion
              FROM (
                SELECT
                  u.subscriber,
                  u.msisdn_counterpart
                FROM unioned AS u
              ) AS u
              INNER JOIN total_events AS t
                ON u.subscriber = t.subscriber
              GROUP BY
                u.subscriber,
                u.msisdn_counterpart,
                t.events
              ORDER BY
                proportion DESC NULLS FIRST
            ) AS c
            ORDER BY
              cum_events DESC NULLS FIRST
          ) AS cu
          LEFT JOIN (
            SELECT
              b.subscriber,
              CEIL(SUM(events * 0.8)) AS target
            FROM (
              WITH unioned AS (
                SELECT
                  *
                FROM (
                  SELECT
                    flowkit_sf1.calls.msisdn AS subscriber,
                    flowkit_sf1.calls.msisdn_counterpart
                  FROM flowkit_sf1.calls
                  WHERE
                    flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
                    AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
                  UNION ALL
                  SELECT
                    flowkit_sf1.sms.msisdn AS subscriber,
                    flowkit_sf1.sms.msisdn_counterpart
                  FROM flowkit_sf1.sms
                  WHERE
                    flowkit_sf1.sms.datetime >= '2016-01-01 00:00:00'
                    AND flowkit_sf1.sms.datetime < '2016-01-08 00:00:00'
                ) AS u
              ), total_events AS (
                SELECT
                  subscriber,
                  COUNT(*) AS events
                FROM unioned
                GROUP BY
                  subscriber
              )
              SELECT
                u.subscriber,
                u.msisdn_counterpart,
                COUNT(*) AS events,
                CAST(COUNT(*) AS DOUBLE) / CAST(t.events AS DOUBLE) AS proportion
              FROM (
                SELECT
                  u.subscriber,
                  u.msisdn_counterpart
                FROM unioned AS u
              ) AS u
              INNER JOIN total_events AS t
                ON u.subscriber = t.subscriber
              GROUP BY
                u.subscriber,
                u.msisdn_counterpart,
                t.events
              ORDER BY
                proportion DESC NULLS FIRST
            ) AS b
            GROUP BY
              b.subscriber
          ) AS tgt
            ON cu.subscriber = tgt.subscriber
          WHERE
            (
              tgt.target - cu.cum_events
            ) <= 0
        ) AS _t
        WHERE
          _row_number = 1
      ) AS uc
      LEFT JOIN (
        SELECT
          subscriber,
          COUNT(*) AS value
        FROM (
          SELECT DISTINCT
            subscriber,
            msisdn_counterpart
          FROM (
            SELECT
              flowkit_sf1.calls.msisdn AS subscriber,
              flowkit_sf1.calls.msisdn_counterpart
            FROM flowkit_sf1.calls
            WHERE
              flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
              AND flowkit_sf1.calls.datetime < '2016-01-08 00:00:00'
            UNION ALL
            SELECT
              flowkit_sf1.sms.msisdn AS subscriber,
              flowkit_sf1.sms.msisdn_counterpart
            FROM flowkit_sf1.sms
            WHERE
              flowkit_sf1.sms.datetime >= '2016-01-01 00:00:00'
              AND flowkit_sf1.sms.datetime < '2016-01-08 00:00:00'
          ) AS u
        ) AS u
        GROUP BY
          subscriber
      ) AS ud
        ON uc.subscriber = ud.subscriber
      ORDER BY
        uc.subscriber NULLS LAST
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
  ) AS joined
  GROUP BY
    pcod
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
