-- duckjob_load.sql
-- Loads IMDB JOB dataset from ./job directory into existing job schema.

USE job;

COPY aka_name        FROM 'job/aka_name.txt'        (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY aka_title       FROM 'job/aka_title.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY cast_info       FROM 'job/cast_info.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY char_name       FROM 'job/char_name.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY comp_cast_type  FROM 'job/comp_cast_type.txt'  (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY company_name    FROM 'job/company_name.txt'    (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY company_type    FROM 'job/company_type.txt'    (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY complete_cast   FROM 'job/complete_cast.txt'   (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY info_type       FROM 'job/info_type.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY keyword         FROM 'job/keyword.txt'         (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY kind_type       FROM 'job/kind_type.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY link_type       FROM 'job/link_type.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY movie_companies FROM 'job/movie_companies.txt' (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY movie_info      FROM 'job/movie_info.txt'      (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY movie_info_idx  FROM 'job/movie_info_idx.txt'  (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY movie_keyword   FROM 'job/movie_keyword.txt'   (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY movie_link      FROM 'job/movie_link.txt'      (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY name            FROM 'job/name.txt'            (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY person_info     FROM 'job/person_info.txt'     (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY role_type       FROM 'job/role_type.txt'       (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');
COPY title           FROM 'job/title.txt'           (NULLSTR '', HEADER FALSE, NULL_PADDING TRUE, ESCAPE '\', QUOTE '"');


-- EXPORT (TPC-style)
-- Pipe-delimited, header row, standard CSV quoting
COPY job.aka_name        TO 'job/aka_name.csv'        (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.aka_title       TO 'job/aka_title.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.cast_info       TO 'job/cast_info.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.char_name       TO 'job/char_name.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.comp_cast_type  TO 'job/comp_cast_type.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.company_name    TO 'job/company_name.csv'    (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.company_type    TO 'job/company_type.csv'    (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.complete_cast   TO 'job/complete_cast.csv'   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.info_type       TO 'job/info_type.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.keyword         TO 'job/keyword.csv'         (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.kind_type       TO 'job/kind_type.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.link_type       TO 'job/link_type.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.movie_companies TO 'job/movie_companies.csv' (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.movie_info      TO 'job/movie_info.csv'      (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.movie_info_idx  TO 'job/movie_info_idx.csv'  (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.movie_keyword   TO 'job/movie_keyword.csv'   (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.movie_link      TO 'job/movie_link.csv'      (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.name            TO 'job/name.csv'            (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.person_info     TO 'job/person_info.csv'     (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.role_type       TO 'job/role_type.csv'       (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');
COPY job.title           TO 'job/title.csv'           (FORMAT CSV, DELIM '|', HEADER TRUE, QUOTE '"', ESCAPE '"');

COPY job.aka_name        TO 'job/aka_name.parquet'        (FORMAT PARQUET);
COPY job.aka_title       TO 'job/aka_title.parquet'       (FORMAT PARQUET);
COPY job.cast_info       TO 'job/cast_info.parquet'       (FORMAT PARQUET);
COPY job.char_name       TO 'job/char_name.parquet'       (FORMAT PARQUET);
COPY job.comp_cast_type  TO 'job/comp_cast_type.parquet'  (FORMAT PARQUET);
COPY job.company_name    TO 'job/company_name.parquet'    (FORMAT PARQUET);
COPY job.company_type    TO 'job/company_type.parquet'    (FORMAT PARQUET);
COPY job.complete_cast   TO 'job/complete_cast.parquet'   (FORMAT PARQUET);
COPY job.info_type       TO 'job/info_type.parquet'       (FORMAT PARQUET);
COPY job.keyword         TO 'job/keyword.parquet'         (FORMAT PARQUET);
COPY job.kind_type       TO 'job/kind_type.parquet'       (FORMAT PARQUET);
COPY job.link_type       TO 'job/link_type.parquet'       (FORMAT PARQUET);
COPY job.movie_companies TO 'job/movie_companies.parquet' (FORMAT PARQUET);
COPY job.movie_info      TO 'job/movie_info.parquet'      (FORMAT PARQUET);
COPY job.movie_info_idx  TO 'job/movie_info_idx.parquet'  (FORMAT PARQUET);
COPY job.movie_keyword   TO 'job/movie_keyword.parquet'   (FORMAT PARQUET);
COPY job.movie_link      TO 'job/movie_link.parquet'      (FORMAT PARQUET);
COPY job.name            TO 'job/name.parquet'            (FORMAT PARQUET);
COPY job.person_info     TO 'job/person_info.parquet'     (FORMAT PARQUET);
COPY job.role_type       TO 'job/role_type.parquet'       (FORMAT PARQUET);
COPY job.title           TO 'job/title.parquet'           (FORMAT PARQUET);