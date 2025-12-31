CREATE OR REPLACE TABLE dim_location AS
SELECT
    UUID_STRING()        AS location_id,
    POSTAL_CODE          AS postal_code,
    CITY_NAME            AS city_name,
    COUNTRY              AS country
FROM postal_codes_staging;

SELECT count(*) from dim_location;
SELECT * from dim_location
limit 5;



CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    TO_VARCHAR(d, 'YYYYMMDD') AS date_id,
    d                           AS date,
    YEAR(d)                    AS year,
    MONTH(d)                   AS month,
    DAY(d)                     AS day,
    DAYOFYEAR(d)               AS day_of_year,
    QUARTER(d)                 AS quarter
FROM (
    SELECT DATE_VALID_STD AS d FROM forecast_day_staging
    UNION
    SELECT DATE_VALID_STD FROM history_day_staging
    UNION
    SELECT DATE_VALID_STD FROM forecast_history_day_staging
);

SELECT count(*) from dim_date;
SELECT * from dim_date
limit 5;

/*
CREATE OR REPLACE TABLE dim_time AS
SELECT DISTINCT
    TO_VARCHAR(TIME_VALID_UTC, 'HH24MI') AS time_id,
    EXTRACT(HOUR   FROM TIME_VALID_UTC)  AS hour,
    EXTRACT(MINUTE FROM TIME_VALID_UTC)  AS minute,
    'UTC'                                AS time_type,
    0                                    AS is_dst,
    TIME_VALID_UTC                       AS time
FROM forecast_hour_staging
WHERE TIME_VALID_UTC IS NOT NULL;


SELECT count(*) from dim_time;
SELECT * from dim_time
limit 5;


CREATE OR REPLACE TABLE dim_weather_type AS
SELECT DISTINCT
    UUID_STRING() AS weather_type_id,
    weather_type
FROM (
    SELECT 'forecast' AS weather_type
    UNION ALL
    SELECT 'history'
);

SELECT count(*) from dim_weather_type;

CREATE OR REPLACE TABLE dim_data_type AS
SELECT DISTINCT
    UUID_STRING() AS data_type_id,
    data_type
FROM (
    SELECT 'day'  AS data_type
    UNION ALL
    SELECT 'hour'
);

SELECT count(*) from dim_data_type;
*/

CREATE OR REPLACE TABLE dim_time AS
SELECT DISTINCT
    TO_VARCHAR(t.time_valid_utc, 'HH24MISS')      AS time_id,
    EXTRACT(HOUR   FROM t.time_valid_utc)         AS hour,
    EXTRACT(MINUTE FROM t.time_valid_utc)         AS minute,
    EXTRACT(SECOND FROM t.time_valid_utc)         AS second,

    CASE 
        WHEN t.dst_offset_minutes <> 0 THEN 1
        ELSE 0
    END                                           AS is_dst,

    t.time_valid_utc                               AS time_utc,
    t.time_valid_lcl                               AS time_local,
    t.dst_offset_minutes                           AS dst_offset_minutes

FROM (
    SELECT time_valid_utc, time_valid_lcl, dst_offset_minutes FROM forecast_hour_staging
    UNION
    SELECT time_valid_utc, time_valid_lcl, dst_offset_minutes FROM history_hour_staging
    UNION
    SELECT time_valid_utc, time_valid_lcl, dst_offset_minutes FROM forecast_history_hour_staging
) t
WHERE t.time_valid_utc IS NOT NULL;

CREATE OR REPLACE TABLE dim_data_type AS
SELECT DISTINCT
    UUID_STRING() AS data_type_id,
    data_type
FROM (
    SELECT 'forecast' AS data_type
    UNION ALL
    SELECT 'measurement'
);

CREATE OR REPLACE TABLE dim_granularity AS
SELECT DISTINCT
    UUID_STRING() AS granularity_id,
    granularity
FROM (
    SELECT 'day' AS granularity
    UNION ALL
    SELECT 'hour'
);

CREATE OR REPLACE TABLE fact_weather AS
SELECT
    UUID_STRING() AS fact_weather_id,
    dl.location_id,
    dd.date_id,
    dt.time_id AS time_id,
    dwt.weather_type_id,
    ddt.data_type_id,
    s.AVG_TEMPERATURE_AIR_2M_F        AS temperature_air_f,
    s.AVG_TEMPERATURE_FEELSLIKE_2M_F  AS feels_like_temperature_f,
    s.TOT_PRECIPITATION_IN            AS precipitation_in,
    s.TOT_SNOWFALL_IN                 AS snowfall_in,
    s.AVG_WIND_SPEED_10M_MPH           AS wind_speed_mph,
    s.AVG_HUMIDITY_RELATIVE_2M_PCT     AS humidity_pct,
    s.AVG_PRESSURE_MEAN_SEA_LEVEL_MB  AS pressure_mb,
    s.AVG_CLOUD_COVER_TOT_PCT          AS cloud_cover_pct,
    s.AVG_RADIATION_SOLAR_TOTAL_WPM2   AS solar_radiation_wpm2,

    AVG(s.AVG_TEMPERATURE_AIR_2M_F) OVER (
        PARTITION BY dl.location_id
        ORDER BY dd.date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_avg_temperature,

   s.AVG_TEMPERATURE_AIR_2M_F - LAG(s.AVG_TEMPERATURE_AIR_2M_F) OVER (
    PARTITION BY dl.location_id
    ORDER BY dd.date
) AS day_temperature_change

FROM forecast_day_staging s
LEFT JOIN dim_time dt
  ON TO_VARCHAR(s.TIME_INIT_UTC, 'HH24MI') = dt.time_id
JOIN dim_location dl
  ON s.POSTAL_CODE = dl.postal_code
 AND s.COUNTRY = dl.country
JOIN dim_date dd
  ON s.DATE_VALID_STD = dd.date
JOIN dim_weather_type dwt
  ON dwt.weather_type = 'forecast'
JOIN dim_data_type ddt
  ON ddt.data_type = 'day';




SELECT * FROM fact_weather
ORDER BY day_temperature_change asc
limit 10;
