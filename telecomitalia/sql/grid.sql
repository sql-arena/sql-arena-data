-- Each square is a closed 5 point ring in EPSG:4326; the centroid is the mean of its 4 corners
CREATE OR REPLACE TABLE _chunk (
    square_id    INTEGER NOT NULL,
    geometry_wkt VARCHAR NOT NULL,
    centroid_lon DOUBLE  NOT NULL,
    centroid_lat DOUBLE  NOT NULL
);

INSERT INTO _chunk
SELECT f.properties.cellId,
       'POLYGON ((' || array_to_string(list_transform(f.geometry.coordinates[1], p -> p[1] || ' ' || p[2]), ', ') || '))',
       list_avg(list_transform(f.geometry.coordinates[1][1:4], p -> p[1])),
       list_avg(list_transform(f.geometry.coordinates[1][1:4], p -> p[2]))
FROM (SELECT unnest(features) AS f FROM read_json(%%PATHS%%, maximum_object_size = 100000000))
ORDER BY ALL;
