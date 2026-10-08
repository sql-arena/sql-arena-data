/* FlowKit Q04: location_event_counts
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "location_event_counts", "start_date": "2016-01-01", "end_date": "2016-01-08", "interval": "day", "aggregation_unit": "admin3", "direction": "both", "event_types": null, "subscriber_subset": null} */
SELECT
  tne.*
FROM (
  (
    (
      (
        (
          (
            SELECT
              pcod,
              CAST(CAST(datetime AS DATE) AS TEXT) AS date,
              COUNT(*) AS value
            FROM (
              SELECT
                l.datetime,
                l.location_id,
                l.subscriber,
                sites.pcod
              FROM (
                SELECT
                  flowkit_sf100.calls.datetime,
                  flowkit_sf100.calls.location_id,
                  flowkit_sf100.calls.msisdn AS subscriber
                FROM flowkit_sf100.calls
                WHERE
                  flowkit_sf100.calls.datetime >= '2016-01-01 00:00:00'
                  AND flowkit_sf100.calls.datetime < '2016-01-02 00:00:00'
                UNION ALL
                SELECT
                  flowkit_sf100.sms.datetime,
                  flowkit_sf100.sms.location_id,
                  flowkit_sf100.sms.msisdn AS subscriber
                FROM flowkit_sf100.sms
                WHERE
                  flowkit_sf100.sms.datetime >= '2016-01-01 00:00:00'
                  AND flowkit_sf100.sms.datetime < '2016-01-02 00:00:00'
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
            ) AS unioned
            GROUP BY
              CAST(CAST(datetime AS DATE) AS TEXT),
              pcod
            UNION ALL
            SELECT
              pcod,
              CAST(CAST(datetime AS DATE) AS TEXT) AS date,
              COUNT(*) AS value
            FROM (
              SELECT
                l.datetime,
                l.location_id,
                l.subscriber,
                sites.pcod
              FROM (
                SELECT
                  flowkit_sf100.calls.datetime,
                  flowkit_sf100.calls.location_id,
                  flowkit_sf100.calls.msisdn AS subscriber
                FROM flowkit_sf100.calls
                WHERE
                  flowkit_sf100.calls.datetime >= '2016-01-02 00:00:00'
                  AND flowkit_sf100.calls.datetime < '2016-01-03 00:00:00'
                UNION ALL
                SELECT
                  flowkit_sf100.sms.datetime,
                  flowkit_sf100.sms.location_id,
                  flowkit_sf100.sms.msisdn AS subscriber
                FROM flowkit_sf100.sms
                WHERE
                  flowkit_sf100.sms.datetime >= '2016-01-02 00:00:00'
                  AND flowkit_sf100.sms.datetime < '2016-01-03 00:00:00'
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
            ) AS unioned
            GROUP BY
              CAST(CAST(datetime AS DATE) AS TEXT),
              pcod
          )
          UNION ALL
          SELECT
            pcod,
            CAST(CAST(datetime AS DATE) AS TEXT) AS date,
            COUNT(*) AS value
          FROM (
            SELECT
              l.datetime,
              l.location_id,
              l.subscriber,
              sites.pcod
            FROM (
              SELECT
                flowkit_sf100.sms.datetime,
                flowkit_sf100.sms.location_id,
                flowkit_sf100.sms.msisdn AS subscriber
              FROM flowkit_sf100.sms
              WHERE
                flowkit_sf100.sms.datetime >= '2016-01-03 00:00:00'
                AND flowkit_sf100.sms.datetime < '2016-01-04 00:00:00'
              UNION ALL
              SELECT
                flowkit_sf100.calls.datetime,
                flowkit_sf100.calls.location_id,
                flowkit_sf100.calls.msisdn AS subscriber
              FROM flowkit_sf100.calls
              WHERE
                flowkit_sf100.calls.datetime >= '2016-01-03 00:00:00'
                AND flowkit_sf100.calls.datetime < '2016-01-04 00:00:00'
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
          ) AS unioned
          GROUP BY
            CAST(CAST(datetime AS DATE) AS TEXT),
            pcod
        )
        UNION ALL
        SELECT
          pcod,
          CAST(CAST(datetime AS DATE) AS TEXT) AS date,
          COUNT(*) AS value
        FROM (
          SELECT
            l.datetime,
            l.location_id,
            l.subscriber,
            sites.pcod
          FROM (
            SELECT
              flowkit_sf100.calls.datetime,
              flowkit_sf100.calls.location_id,
              flowkit_sf100.calls.msisdn AS subscriber
            FROM flowkit_sf100.calls
            WHERE
              flowkit_sf100.calls.datetime >= '2016-01-04 00:00:00'
              AND flowkit_sf100.calls.datetime < '2016-01-05 00:00:00'
            UNION ALL
            SELECT
              flowkit_sf100.sms.datetime,
              flowkit_sf100.sms.location_id,
              flowkit_sf100.sms.msisdn AS subscriber
            FROM flowkit_sf100.sms
            WHERE
              flowkit_sf100.sms.datetime >= '2016-01-04 00:00:00'
              AND flowkit_sf100.sms.datetime < '2016-01-05 00:00:00'
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
        ) AS unioned
        GROUP BY
          CAST(CAST(datetime AS DATE) AS TEXT),
          pcod
      )
      UNION ALL
      SELECT
        pcod,
        CAST(CAST(datetime AS DATE) AS TEXT) AS date,
        COUNT(*) AS value
      FROM (
        SELECT
          l.datetime,
          l.location_id,
          l.subscriber,
          sites.pcod
        FROM (
          SELECT
            flowkit_sf100.calls.datetime,
            flowkit_sf100.calls.location_id,
            flowkit_sf100.calls.msisdn AS subscriber
          FROM flowkit_sf100.calls
          WHERE
            flowkit_sf100.calls.datetime >= '2016-01-05 00:00:00'
            AND flowkit_sf100.calls.datetime < '2016-01-06 00:00:00'
          UNION ALL
          SELECT
            flowkit_sf100.sms.datetime,
            flowkit_sf100.sms.location_id,
            flowkit_sf100.sms.msisdn AS subscriber
          FROM flowkit_sf100.sms
          WHERE
            flowkit_sf100.sms.datetime >= '2016-01-05 00:00:00'
            AND flowkit_sf100.sms.datetime < '2016-01-06 00:00:00'
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
      ) AS unioned
      GROUP BY
        CAST(CAST(datetime AS DATE) AS TEXT),
        pcod
    )
    UNION ALL
    SELECT
      pcod,
      CAST(CAST(datetime AS DATE) AS TEXT) AS date,
      COUNT(*) AS value
    FROM (
      SELECT
        l.datetime,
        l.location_id,
        l.subscriber,
        sites.pcod
      FROM (
        SELECT
          flowkit_sf100.calls.datetime,
          flowkit_sf100.calls.location_id,
          flowkit_sf100.calls.msisdn AS subscriber
        FROM flowkit_sf100.calls
        WHERE
          flowkit_sf100.calls.datetime >= '2016-01-06 00:00:00'
          AND flowkit_sf100.calls.datetime < '2016-01-07 00:00:00'
        UNION ALL
        SELECT
          flowkit_sf100.sms.datetime,
          flowkit_sf100.sms.location_id,
          flowkit_sf100.sms.msisdn AS subscriber
        FROM flowkit_sf100.sms
        WHERE
          flowkit_sf100.sms.datetime >= '2016-01-06 00:00:00'
          AND flowkit_sf100.sms.datetime < '2016-01-07 00:00:00'
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
    ) AS unioned
    GROUP BY
      CAST(CAST(datetime AS DATE) AS TEXT),
      pcod
  )
  UNION ALL
  SELECT
    pcod,
    CAST(CAST(datetime AS DATE) AS TEXT) AS date,
    COUNT(*) AS value
  FROM (
    SELECT
      l.datetime,
      l.location_id,
      l.subscriber,
      sites.pcod
    FROM (
      SELECT
        flowkit_sf100.calls.datetime,
        flowkit_sf100.calls.location_id,
        flowkit_sf100.calls.msisdn AS subscriber
      FROM flowkit_sf100.calls
      WHERE
        flowkit_sf100.calls.datetime >= '2016-01-07 00:00:00'
        AND flowkit_sf100.calls.datetime < '2016-01-08 00:00:00'
      UNION ALL
      SELECT
        flowkit_sf100.sms.datetime,
        flowkit_sf100.sms.location_id,
        flowkit_sf100.sms.msisdn AS subscriber
      FROM flowkit_sf100.sms
      WHERE
        flowkit_sf100.sms.datetime >= '2016-01-07 00:00:00'
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
  ) AS unioned
  GROUP BY
    CAST(CAST(datetime AS DATE) AS TEXT),
    pcod
) AS tne
INNER JOIN (
  (
    (
      (
        (
          (
            SELECT
              '2016-01-01' AS date,
              pcod
            FROM (
              SELECT
                pcod,
                value
              FROM (
                SELECT
                  pcod,
                  COUNT(unique_subscribers) AS value
                FROM (
                  SELECT
                    pcod,
                    all_locs.subscriber AS unique_subscribers
                  FROM (
                    SELECT
                      subscriber,
                      pcod
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
                            flowkit_sf100.calls.datetime,
                            flowkit_sf100.calls.location_id,
                            flowkit_sf100.calls.msisdn AS subscriber
                          FROM flowkit_sf100.calls
                          WHERE
                            flowkit_sf100.calls.datetime >= '2016-01-01 00:00:00'
                            AND flowkit_sf100.calls.datetime < '2016-01-02 00:00:00'
                          UNION ALL
                          SELECT
                            flowkit_sf100.sms.datetime,
                            flowkit_sf100.sms.location_id,
                            flowkit_sf100.sms.msisdn AS subscriber
                          FROM flowkit_sf100.sms
                          WHERE
                            flowkit_sf100.sms.datetime >= '2016-01-01 00:00:00'
                            AND flowkit_sf100.sms.datetime < '2016-01-02 00:00:00'
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
                      ) AS foo
                      WHERE
                        location_id IS NOT NULL AND location_id <> ''
                    ) AS _
                    GROUP BY
                      subscriber,
                      pcod
                  ) AS all_locs
                ) AS _
                GROUP BY
                  pcod
              ) AS agged
              WHERE
                agged.value > 15
            ) AS _
            UNION ALL
            SELECT
              '2016-01-02' AS date,
              pcod
            FROM (
              SELECT
                pcod,
                value
              FROM (
                SELECT
                  pcod,
                  COUNT(unique_subscribers) AS value
                FROM (
                  SELECT
                    pcod,
                    all_locs.subscriber AS unique_subscribers
                  FROM (
                    SELECT
                      subscriber,
                      pcod
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
                            flowkit_sf100.calls.datetime,
                            flowkit_sf100.calls.location_id,
                            flowkit_sf100.calls.msisdn AS subscriber
                          FROM flowkit_sf100.calls
                          WHERE
                            flowkit_sf100.calls.datetime >= '2016-01-02 00:00:00'
                            AND flowkit_sf100.calls.datetime < '2016-01-03 00:00:00'
                          UNION ALL
                          SELECT
                            flowkit_sf100.sms.datetime,
                            flowkit_sf100.sms.location_id,
                            flowkit_sf100.sms.msisdn AS subscriber
                          FROM flowkit_sf100.sms
                          WHERE
                            flowkit_sf100.sms.datetime >= '2016-01-02 00:00:00'
                            AND flowkit_sf100.sms.datetime < '2016-01-03 00:00:00'
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
                      ) AS foo
                      WHERE
                        location_id IS NOT NULL AND location_id <> ''
                    ) AS _
                    GROUP BY
                      subscriber,
                      pcod
                  ) AS all_locs
                ) AS _
                GROUP BY
                  pcod
              ) AS agged
              WHERE
                agged.value > 15
            ) AS _
          )
          UNION ALL
          SELECT
            '2016-01-03' AS date,
            pcod
          FROM (
            SELECT
              pcod,
              value
            FROM (
              SELECT
                pcod,
                COUNT(unique_subscribers) AS value
              FROM (
                SELECT
                  pcod,
                  all_locs.subscriber AS unique_subscribers
                FROM (
                  SELECT
                    subscriber,
                    pcod
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
                          flowkit_sf100.sms.datetime,
                          flowkit_sf100.sms.location_id,
                          flowkit_sf100.sms.msisdn AS subscriber
                        FROM flowkit_sf100.sms
                        WHERE
                          flowkit_sf100.sms.datetime >= '2016-01-03 00:00:00'
                          AND flowkit_sf100.sms.datetime < '2016-01-04 00:00:00'
                        UNION ALL
                        SELECT
                          flowkit_sf100.calls.datetime,
                          flowkit_sf100.calls.location_id,
                          flowkit_sf100.calls.msisdn AS subscriber
                        FROM flowkit_sf100.calls
                        WHERE
                          flowkit_sf100.calls.datetime >= '2016-01-03 00:00:00'
                          AND flowkit_sf100.calls.datetime < '2016-01-04 00:00:00'
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
                    ) AS foo
                    WHERE
                      location_id IS NOT NULL AND location_id <> ''
                  ) AS _
                  GROUP BY
                    subscriber,
                    pcod
                ) AS all_locs
              ) AS _
              GROUP BY
                pcod
            ) AS agged
            WHERE
              agged.value > 15
          ) AS _
        )
        UNION ALL
        SELECT
          '2016-01-04' AS date,
          pcod
        FROM (
          SELECT
            pcod,
            value
          FROM (
            SELECT
              pcod,
              COUNT(unique_subscribers) AS value
            FROM (
              SELECT
                pcod,
                all_locs.subscriber AS unique_subscribers
              FROM (
                SELECT
                  subscriber,
                  pcod
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
                        flowkit_sf100.calls.datetime,
                        flowkit_sf100.calls.location_id,
                        flowkit_sf100.calls.msisdn AS subscriber
                      FROM flowkit_sf100.calls
                      WHERE
                        flowkit_sf100.calls.datetime >= '2016-01-04 00:00:00'
                        AND flowkit_sf100.calls.datetime < '2016-01-05 00:00:00'
                      UNION ALL
                      SELECT
                        flowkit_sf100.sms.datetime,
                        flowkit_sf100.sms.location_id,
                        flowkit_sf100.sms.msisdn AS subscriber
                      FROM flowkit_sf100.sms
                      WHERE
                        flowkit_sf100.sms.datetime >= '2016-01-04 00:00:00'
                        AND flowkit_sf100.sms.datetime < '2016-01-05 00:00:00'
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
                  ) AS foo
                  WHERE
                    location_id IS NOT NULL AND location_id <> ''
                ) AS _
                GROUP BY
                  subscriber,
                  pcod
              ) AS all_locs
            ) AS _
            GROUP BY
              pcod
          ) AS agged
          WHERE
            agged.value > 15
        ) AS _
      )
      UNION ALL
      SELECT
        '2016-01-05' AS date,
        pcod
      FROM (
        SELECT
          pcod,
          value
        FROM (
          SELECT
            pcod,
            COUNT(unique_subscribers) AS value
          FROM (
            SELECT
              pcod,
              all_locs.subscriber AS unique_subscribers
            FROM (
              SELECT
                subscriber,
                pcod
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
                      flowkit_sf100.calls.datetime,
                      flowkit_sf100.calls.location_id,
                      flowkit_sf100.calls.msisdn AS subscriber
                    FROM flowkit_sf100.calls
                    WHERE
                      flowkit_sf100.calls.datetime >= '2016-01-05 00:00:00'
                      AND flowkit_sf100.calls.datetime < '2016-01-06 00:00:00'
                    UNION ALL
                    SELECT
                      flowkit_sf100.sms.datetime,
                      flowkit_sf100.sms.location_id,
                      flowkit_sf100.sms.msisdn AS subscriber
                    FROM flowkit_sf100.sms
                    WHERE
                      flowkit_sf100.sms.datetime >= '2016-01-05 00:00:00'
                      AND flowkit_sf100.sms.datetime < '2016-01-06 00:00:00'
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
                ) AS foo
                WHERE
                  location_id IS NOT NULL AND location_id <> ''
              ) AS _
              GROUP BY
                subscriber,
                pcod
            ) AS all_locs
          ) AS _
          GROUP BY
            pcod
        ) AS agged
        WHERE
          agged.value > 15
      ) AS _
    )
    UNION ALL
    SELECT
      '2016-01-06' AS date,
      pcod
    FROM (
      SELECT
        pcod,
        value
      FROM (
        SELECT
          pcod,
          COUNT(unique_subscribers) AS value
        FROM (
          SELECT
            pcod,
            all_locs.subscriber AS unique_subscribers
          FROM (
            SELECT
              subscriber,
              pcod
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
                    flowkit_sf100.calls.datetime,
                    flowkit_sf100.calls.location_id,
                    flowkit_sf100.calls.msisdn AS subscriber
                  FROM flowkit_sf100.calls
                  WHERE
                    flowkit_sf100.calls.datetime >= '2016-01-06 00:00:00'
                    AND flowkit_sf100.calls.datetime < '2016-01-07 00:00:00'
                  UNION ALL
                  SELECT
                    flowkit_sf100.sms.datetime,
                    flowkit_sf100.sms.location_id,
                    flowkit_sf100.sms.msisdn AS subscriber
                  FROM flowkit_sf100.sms
                  WHERE
                    flowkit_sf100.sms.datetime >= '2016-01-06 00:00:00'
                    AND flowkit_sf100.sms.datetime < '2016-01-07 00:00:00'
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
              ) AS foo
              WHERE
                location_id IS NOT NULL AND location_id <> ''
            ) AS _
            GROUP BY
              subscriber,
              pcod
          ) AS all_locs
        ) AS _
        GROUP BY
          pcod
      ) AS agged
      WHERE
        agged.value > 15
    ) AS _
  )
  UNION ALL
  SELECT
    '2016-01-07' AS date,
    pcod
  FROM (
    SELECT
      pcod,
      value
    FROM (
      SELECT
        pcod,
        COUNT(unique_subscribers) AS value
      FROM (
        SELECT
          pcod,
          all_locs.subscriber AS unique_subscribers
        FROM (
          SELECT
            subscriber,
            pcod
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
                  flowkit_sf100.calls.datetime,
                  flowkit_sf100.calls.location_id,
                  flowkit_sf100.calls.msisdn AS subscriber
                FROM flowkit_sf100.calls
                WHERE
                  flowkit_sf100.calls.datetime >= '2016-01-07 00:00:00'
                  AND flowkit_sf100.calls.datetime < '2016-01-08 00:00:00'
                UNION ALL
                SELECT
                  flowkit_sf100.sms.datetime,
                  flowkit_sf100.sms.location_id,
                  flowkit_sf100.sms.msisdn AS subscriber
                FROM flowkit_sf100.sms
                WHERE
                  flowkit_sf100.sms.datetime >= '2016-01-07 00:00:00'
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
            ) AS foo
            WHERE
              location_id IS NOT NULL AND location_id <> ''
          ) AS _
          GROUP BY
            subscriber,
            pcod
        ) AS all_locs
      ) AS _
      GROUP BY
        pcod
    ) AS agged
    WHERE
      agged.value > 15
  ) AS _
) AS redactor
  USING (pcod, date);
