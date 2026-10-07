/* FlowKit Q05: location_event_counts
   
   Rendered by Flowminder FlowKit flowmachine (https://github.com/Flowminder/FlowKit, commit 24d88247d57987fe33f6b8915540d7bf09b58033)
   and rewritten to portable SQL for SQL Arena.
   This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of
   the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
   
   FlowAPI query spec:
   {"query_kind": "location_event_counts", "start_date": "2016-01-01", "end_date": "2016-01-02", "interval": "hour", "aggregation_unit": "admin1", "direction": "out", "event_types": ["calls"], "subscriber_subset": null} */
SELECT
  tne.*
FROM (
  SELECT
    pcod,
    CAST(CAST(datetime AS DATE) AS TEXT) AS date,
    EXTRACT(HOUR FROM datetime) AS hour,
    COUNT(*) AS value
  FROM (
    SELECT
      l.datetime,
      l.location_id,
      l.subscriber,
      l.outgoing,
      sites.pcod
    FROM (
      SELECT
        flowkit_sf1.calls.datetime,
        flowkit_sf1.calls.location_id,
        flowkit_sf1.calls.msisdn AS subscriber,
        flowkit_sf1.calls.outgoing
      FROM flowkit_sf1.calls
      WHERE
        flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
        AND flowkit_sf1.calls.datetime < '2016-01-02 00:00:00'
    ) AS l
    INNER JOIN (
      SELECT
        loc_table.id AS location_id,
        loc_table.date_of_first_service,
        loc_table.date_of_last_service,
        geom_table.admin1pcod AS pcod
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
  ) AS unioned
  WHERE
    outgoing
  GROUP BY
    CAST(CAST(datetime AS DATE) AS TEXT),
    EXTRACT(HOUR FROM datetime),
    pcod
) AS tne
INNER JOIN (
  (
    (
      (
        (
          (
            (
              (
                (
                  (
                    (
                      (
                        (
                          (
                            (
                              (
                                (
                                  (
                                    (
                                      (
                                        (
                                          (
                                            (
                                              SELECT
                                                '2016-01-01' AS date,
                                                0 AS hour,
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
                                                              flowkit_sf1.calls.datetime,
                                                              flowkit_sf1.calls.location_id,
                                                              flowkit_sf1.calls.msisdn AS subscriber
                                                            FROM flowkit_sf1.calls
                                                            WHERE
                                                              flowkit_sf1.calls.datetime >= '2016-01-01 00:00:00'
                                                              AND flowkit_sf1.calls.datetime < '2016-01-01 01:00:00'
                                                          ) AS l
                                                          INNER JOIN (
                                                            SELECT
                                                              loc_table.id AS location_id,
                                                              loc_table.date_of_first_service,
                                                              loc_table.date_of_last_service,
                                                              geom_table.admin1pcod AS pcod
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
                                                '2016-01-01' AS date,
                                                1 AS hour,
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
                                                              flowkit_sf1.calls.datetime,
                                                              flowkit_sf1.calls.location_id,
                                                              flowkit_sf1.calls.msisdn AS subscriber
                                                            FROM flowkit_sf1.calls
                                                            WHERE
                                                              flowkit_sf1.calls.datetime >= '2016-01-01 01:00:00'
                                                              AND flowkit_sf1.calls.datetime < '2016-01-01 02:00:00'
                                                          ) AS l
                                                          INNER JOIN (
                                                            SELECT
                                                              loc_table.id AS location_id,
                                                              loc_table.date_of_first_service,
                                                              loc_table.date_of_last_service,
                                                              geom_table.admin1pcod AS pcod
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
                                              '2016-01-01' AS date,
                                              2 AS hour,
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
                                                            flowkit_sf1.calls.datetime,
                                                            flowkit_sf1.calls.location_id,
                                                            flowkit_sf1.calls.msisdn AS subscriber
                                                          FROM flowkit_sf1.calls
                                                          WHERE
                                                            flowkit_sf1.calls.datetime >= '2016-01-01 02:00:00'
                                                            AND flowkit_sf1.calls.datetime < '2016-01-01 03:00:00'
                                                        ) AS l
                                                        INNER JOIN (
                                                          SELECT
                                                            loc_table.id AS location_id,
                                                            loc_table.date_of_first_service,
                                                            loc_table.date_of_last_service,
                                                            geom_table.admin1pcod AS pcod
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
                                            '2016-01-01' AS date,
                                            3 AS hour,
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
                                                          flowkit_sf1.calls.datetime,
                                                          flowkit_sf1.calls.location_id,
                                                          flowkit_sf1.calls.msisdn AS subscriber
                                                        FROM flowkit_sf1.calls
                                                        WHERE
                                                          flowkit_sf1.calls.datetime >= '2016-01-01 03:00:00'
                                                          AND flowkit_sf1.calls.datetime < '2016-01-01 04:00:00'
                                                      ) AS l
                                                      INNER JOIN (
                                                        SELECT
                                                          loc_table.id AS location_id,
                                                          loc_table.date_of_first_service,
                                                          loc_table.date_of_last_service,
                                                          geom_table.admin1pcod AS pcod
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
                                          '2016-01-01' AS date,
                                          4 AS hour,
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
                                                        flowkit_sf1.calls.datetime,
                                                        flowkit_sf1.calls.location_id,
                                                        flowkit_sf1.calls.msisdn AS subscriber
                                                      FROM flowkit_sf1.calls
                                                      WHERE
                                                        flowkit_sf1.calls.datetime >= '2016-01-01 04:00:00'
                                                        AND flowkit_sf1.calls.datetime < '2016-01-01 05:00:00'
                                                    ) AS l
                                                    INNER JOIN (
                                                      SELECT
                                                        loc_table.id AS location_id,
                                                        loc_table.date_of_first_service,
                                                        loc_table.date_of_last_service,
                                                        geom_table.admin1pcod AS pcod
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
                                        '2016-01-01' AS date,
                                        5 AS hour,
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
                                                      flowkit_sf1.calls.datetime,
                                                      flowkit_sf1.calls.location_id,
                                                      flowkit_sf1.calls.msisdn AS subscriber
                                                    FROM flowkit_sf1.calls
                                                    WHERE
                                                      flowkit_sf1.calls.datetime >= '2016-01-01 05:00:00'
                                                      AND flowkit_sf1.calls.datetime < '2016-01-01 06:00:00'
                                                  ) AS l
                                                  INNER JOIN (
                                                    SELECT
                                                      loc_table.id AS location_id,
                                                      loc_table.date_of_first_service,
                                                      loc_table.date_of_last_service,
                                                      geom_table.admin1pcod AS pcod
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
                                      '2016-01-01' AS date,
                                      6 AS hour,
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
                                                    flowkit_sf1.calls.datetime,
                                                    flowkit_sf1.calls.location_id,
                                                    flowkit_sf1.calls.msisdn AS subscriber
                                                  FROM flowkit_sf1.calls
                                                  WHERE
                                                    flowkit_sf1.calls.datetime >= '2016-01-01 06:00:00'
                                                    AND flowkit_sf1.calls.datetime < '2016-01-01 07:00:00'
                                                ) AS l
                                                INNER JOIN (
                                                  SELECT
                                                    loc_table.id AS location_id,
                                                    loc_table.date_of_first_service,
                                                    loc_table.date_of_last_service,
                                                    geom_table.admin1pcod AS pcod
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
                                    '2016-01-01' AS date,
                                    7 AS hour,
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
                                                  flowkit_sf1.calls.datetime,
                                                  flowkit_sf1.calls.location_id,
                                                  flowkit_sf1.calls.msisdn AS subscriber
                                                FROM flowkit_sf1.calls
                                                WHERE
                                                  flowkit_sf1.calls.datetime >= '2016-01-01 07:00:00'
                                                  AND flowkit_sf1.calls.datetime < '2016-01-01 08:00:00'
                                              ) AS l
                                              INNER JOIN (
                                                SELECT
                                                  loc_table.id AS location_id,
                                                  loc_table.date_of_first_service,
                                                  loc_table.date_of_last_service,
                                                  geom_table.admin1pcod AS pcod
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
                                  '2016-01-01' AS date,
                                  8 AS hour,
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
                                                flowkit_sf1.calls.datetime,
                                                flowkit_sf1.calls.location_id,
                                                flowkit_sf1.calls.msisdn AS subscriber
                                              FROM flowkit_sf1.calls
                                              WHERE
                                                flowkit_sf1.calls.datetime >= '2016-01-01 08:00:00'
                                                AND flowkit_sf1.calls.datetime < '2016-01-01 09:00:00'
                                            ) AS l
                                            INNER JOIN (
                                              SELECT
                                                loc_table.id AS location_id,
                                                loc_table.date_of_first_service,
                                                loc_table.date_of_last_service,
                                                geom_table.admin1pcod AS pcod
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
                                '2016-01-01' AS date,
                                9 AS hour,
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
                                              flowkit_sf1.calls.datetime,
                                              flowkit_sf1.calls.location_id,
                                              flowkit_sf1.calls.msisdn AS subscriber
                                            FROM flowkit_sf1.calls
                                            WHERE
                                              flowkit_sf1.calls.datetime >= '2016-01-01 09:00:00'
                                              AND flowkit_sf1.calls.datetime < '2016-01-01 10:00:00'
                                          ) AS l
                                          INNER JOIN (
                                            SELECT
                                              loc_table.id AS location_id,
                                              loc_table.date_of_first_service,
                                              loc_table.date_of_last_service,
                                              geom_table.admin1pcod AS pcod
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
                              '2016-01-01' AS date,
                              10 AS hour,
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
                                            flowkit_sf1.calls.datetime,
                                            flowkit_sf1.calls.location_id,
                                            flowkit_sf1.calls.msisdn AS subscriber
                                          FROM flowkit_sf1.calls
                                          WHERE
                                            flowkit_sf1.calls.datetime >= '2016-01-01 10:00:00'
                                            AND flowkit_sf1.calls.datetime < '2016-01-01 11:00:00'
                                        ) AS l
                                        INNER JOIN (
                                          SELECT
                                            loc_table.id AS location_id,
                                            loc_table.date_of_first_service,
                                            loc_table.date_of_last_service,
                                            geom_table.admin1pcod AS pcod
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
                            '2016-01-01' AS date,
                            11 AS hour,
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
                                          flowkit_sf1.calls.datetime,
                                          flowkit_sf1.calls.location_id,
                                          flowkit_sf1.calls.msisdn AS subscriber
                                        FROM flowkit_sf1.calls
                                        WHERE
                                          flowkit_sf1.calls.datetime >= '2016-01-01 11:00:00'
                                          AND flowkit_sf1.calls.datetime < '2016-01-01 12:00:00'
                                      ) AS l
                                      INNER JOIN (
                                        SELECT
                                          loc_table.id AS location_id,
                                          loc_table.date_of_first_service,
                                          loc_table.date_of_last_service,
                                          geom_table.admin1pcod AS pcod
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
                          '2016-01-01' AS date,
                          12 AS hour,
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
                                        flowkit_sf1.calls.datetime,
                                        flowkit_sf1.calls.location_id,
                                        flowkit_sf1.calls.msisdn AS subscriber
                                      FROM flowkit_sf1.calls
                                      WHERE
                                        flowkit_sf1.calls.datetime >= '2016-01-01 12:00:00'
                                        AND flowkit_sf1.calls.datetime < '2016-01-01 13:00:00'
                                    ) AS l
                                    INNER JOIN (
                                      SELECT
                                        loc_table.id AS location_id,
                                        loc_table.date_of_first_service,
                                        loc_table.date_of_last_service,
                                        geom_table.admin1pcod AS pcod
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
                        '2016-01-01' AS date,
                        13 AS hour,
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
                                      flowkit_sf1.calls.datetime,
                                      flowkit_sf1.calls.location_id,
                                      flowkit_sf1.calls.msisdn AS subscriber
                                    FROM flowkit_sf1.calls
                                    WHERE
                                      flowkit_sf1.calls.datetime >= '2016-01-01 13:00:00'
                                      AND flowkit_sf1.calls.datetime < '2016-01-01 14:00:00'
                                  ) AS l
                                  INNER JOIN (
                                    SELECT
                                      loc_table.id AS location_id,
                                      loc_table.date_of_first_service,
                                      loc_table.date_of_last_service,
                                      geom_table.admin1pcod AS pcod
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
                      '2016-01-01' AS date,
                      14 AS hour,
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
                                    flowkit_sf1.calls.datetime,
                                    flowkit_sf1.calls.location_id,
                                    flowkit_sf1.calls.msisdn AS subscriber
                                  FROM flowkit_sf1.calls
                                  WHERE
                                    flowkit_sf1.calls.datetime >= '2016-01-01 14:00:00'
                                    AND flowkit_sf1.calls.datetime < '2016-01-01 15:00:00'
                                ) AS l
                                INNER JOIN (
                                  SELECT
                                    loc_table.id AS location_id,
                                    loc_table.date_of_first_service,
                                    loc_table.date_of_last_service,
                                    geom_table.admin1pcod AS pcod
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
                    '2016-01-01' AS date,
                    15 AS hour,
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
                                  flowkit_sf1.calls.datetime,
                                  flowkit_sf1.calls.location_id,
                                  flowkit_sf1.calls.msisdn AS subscriber
                                FROM flowkit_sf1.calls
                                WHERE
                                  flowkit_sf1.calls.datetime >= '2016-01-01 15:00:00'
                                  AND flowkit_sf1.calls.datetime < '2016-01-01 16:00:00'
                              ) AS l
                              INNER JOIN (
                                SELECT
                                  loc_table.id AS location_id,
                                  loc_table.date_of_first_service,
                                  loc_table.date_of_last_service,
                                  geom_table.admin1pcod AS pcod
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
                  '2016-01-01' AS date,
                  16 AS hour,
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
                                flowkit_sf1.calls.datetime,
                                flowkit_sf1.calls.location_id,
                                flowkit_sf1.calls.msisdn AS subscriber
                              FROM flowkit_sf1.calls
                              WHERE
                                flowkit_sf1.calls.datetime >= '2016-01-01 16:00:00'
                                AND flowkit_sf1.calls.datetime < '2016-01-01 17:00:00'
                            ) AS l
                            INNER JOIN (
                              SELECT
                                loc_table.id AS location_id,
                                loc_table.date_of_first_service,
                                loc_table.date_of_last_service,
                                geom_table.admin1pcod AS pcod
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
                '2016-01-01' AS date,
                17 AS hour,
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
                              flowkit_sf1.calls.datetime,
                              flowkit_sf1.calls.location_id,
                              flowkit_sf1.calls.msisdn AS subscriber
                            FROM flowkit_sf1.calls
                            WHERE
                              flowkit_sf1.calls.datetime >= '2016-01-01 17:00:00'
                              AND flowkit_sf1.calls.datetime < '2016-01-01 18:00:00'
                          ) AS l
                          INNER JOIN (
                            SELECT
                              loc_table.id AS location_id,
                              loc_table.date_of_first_service,
                              loc_table.date_of_last_service,
                              geom_table.admin1pcod AS pcod
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
              '2016-01-01' AS date,
              18 AS hour,
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
                            flowkit_sf1.calls.datetime,
                            flowkit_sf1.calls.location_id,
                            flowkit_sf1.calls.msisdn AS subscriber
                          FROM flowkit_sf1.calls
                          WHERE
                            flowkit_sf1.calls.datetime >= '2016-01-01 18:00:00'
                            AND flowkit_sf1.calls.datetime < '2016-01-01 19:00:00'
                        ) AS l
                        INNER JOIN (
                          SELECT
                            loc_table.id AS location_id,
                            loc_table.date_of_first_service,
                            loc_table.date_of_last_service,
                            geom_table.admin1pcod AS pcod
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
            '2016-01-01' AS date,
            19 AS hour,
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
                          flowkit_sf1.calls.datetime,
                          flowkit_sf1.calls.location_id,
                          flowkit_sf1.calls.msisdn AS subscriber
                        FROM flowkit_sf1.calls
                        WHERE
                          flowkit_sf1.calls.datetime >= '2016-01-01 19:00:00'
                          AND flowkit_sf1.calls.datetime < '2016-01-01 20:00:00'
                      ) AS l
                      INNER JOIN (
                        SELECT
                          loc_table.id AS location_id,
                          loc_table.date_of_first_service,
                          loc_table.date_of_last_service,
                          geom_table.admin1pcod AS pcod
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
          '2016-01-01' AS date,
          20 AS hour,
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
                        flowkit_sf1.calls.datetime,
                        flowkit_sf1.calls.location_id,
                        flowkit_sf1.calls.msisdn AS subscriber
                      FROM flowkit_sf1.calls
                      WHERE
                        flowkit_sf1.calls.datetime >= '2016-01-01 20:00:00'
                        AND flowkit_sf1.calls.datetime < '2016-01-01 21:00:00'
                    ) AS l
                    INNER JOIN (
                      SELECT
                        loc_table.id AS location_id,
                        loc_table.date_of_first_service,
                        loc_table.date_of_last_service,
                        geom_table.admin1pcod AS pcod
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
        '2016-01-01' AS date,
        21 AS hour,
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
                      flowkit_sf1.calls.datetime,
                      flowkit_sf1.calls.location_id,
                      flowkit_sf1.calls.msisdn AS subscriber
                    FROM flowkit_sf1.calls
                    WHERE
                      flowkit_sf1.calls.datetime >= '2016-01-01 21:00:00'
                      AND flowkit_sf1.calls.datetime < '2016-01-01 22:00:00'
                  ) AS l
                  INNER JOIN (
                    SELECT
                      loc_table.id AS location_id,
                      loc_table.date_of_first_service,
                      loc_table.date_of_last_service,
                      geom_table.admin1pcod AS pcod
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
      '2016-01-01' AS date,
      22 AS hour,
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
                    flowkit_sf1.calls.datetime,
                    flowkit_sf1.calls.location_id,
                    flowkit_sf1.calls.msisdn AS subscriber
                  FROM flowkit_sf1.calls
                  WHERE
                    flowkit_sf1.calls.datetime >= '2016-01-01 22:00:00'
                    AND flowkit_sf1.calls.datetime < '2016-01-01 23:00:00'
                ) AS l
                INNER JOIN (
                  SELECT
                    loc_table.id AS location_id,
                    loc_table.date_of_first_service,
                    loc_table.date_of_last_service,
                    geom_table.admin1pcod AS pcod
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
    '2016-01-01' AS date,
    23 AS hour,
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
                  flowkit_sf1.calls.datetime,
                  flowkit_sf1.calls.location_id,
                  flowkit_sf1.calls.msisdn AS subscriber
                FROM flowkit_sf1.calls
                WHERE
                  flowkit_sf1.calls.datetime >= '2016-01-01 23:00:00'
                  AND flowkit_sf1.calls.datetime < '2016-01-02 00:00:00'
              ) AS l
              INNER JOIN (
                SELECT
                  loc_table.id AS location_id,
                  loc_table.date_of_first_service,
                  loc_table.date_of_last_service,
                  geom_table.admin1pcod AS pcod
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
  USING (pcod, date, hour);
