
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
    TO_VARCHAR(DATE_VALID_STD, 'YYYYMMDD') AS date_id,
    DATE_VALID_STD                         AS date,
    YEAR(DATE_VALID_STD)                   AS year,
    MONTH(DATE_VALID_STD)                  AS month,
    DAY(DATE_VALID_STD)                    AS day,
    DAYOFYEAR(DATE_VALID_STD)              AS day_of_year,
    QUARTER(DATE_VALID_STD)                AS quarter
FROM forecast_day_staging;

SELECT count(*) from dim_date;
SELECT * from dim_date
limit 5;


CREATE OR REPLACE TABLE dim_time AS
SELECT DISTINCT
    TO_VARCHAR(TIME_VALID_UTC, 'HH24MI') AS time_id,
    EXTRACT(HOUR   FROM TIME_VALID_UTC)  AS hour,
    EXTRACT(MINUTE FROM TIME_VALID_UTC)  AS minute,
    0                                    AS second,
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




CREATE OR REPLACE TABLE fact_weather AS
SELECT
    UUID_STRING() AS fact_weather_id,

    dl.location_id,
    dd.date_id,
    NULL AS time_id,
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
    ) AS avg_temperature_per_location,

    ROW_NUMBER() OVER (
        PARTITION BY dl.location_id, dd.date_id
        ORDER BY dd.date_id
    ) AS measurement_order

FROM forecast_day_staging s

LEFT JOIN dim_time dt
  ON TO_VARCHAR(s.TIME_INIT_UTC, 'HH24MISS') = dt.time_id

JOIN dim_location dl
  ON s.POSTAL_CODE = dl.postal_code
 AND s.COUNTRY = dl.country

JOIN dim_date dd
  ON s.DATE_VALID_STD = dd.DATE

JOIN dim_weather_type dwt
  ON dwt.weather_type = 'forecast'

JOIN dim_data_type ddt
  ON ddt.data_type = 'day';





SELECT * FROM fact_weather
limit 5;