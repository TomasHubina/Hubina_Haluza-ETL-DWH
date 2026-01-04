--TOTO JE PLATNE

CREATE OR REPLACE TABLE dim_location AS
SELECT
    UUID_STRING()        AS location_id,
    POSTAL_CODE          AS postal_code,
    CITY_NAME            AS city_name,
    COUNTRY              AS country
FROM postal_codes_staging;


--TOTO JE PLATNE
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
    SELECT DATE_VALID_STD AS d FROM history_day_staging
    UNION
    SELECT DATE_VALID_STD FROM forecast_history_day_staging
);


--TOTO JE PLATNE
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
    SELECT 'forecast' AS data_type
    UNION ALL
    SELECT 'measurement'
);

--TOTO JE PLATNE
CREATE OR REPLACE TABLE dim_granularity AS
SELECT DISTINCT
    UUID_STRING() AS granularity_id,
    granularity
FROM (
    SELECT 'day' AS granularity
    UNION ALL
    SELECT 'hour'
);


--TOTO JE PLATNE
CREATE OR REPLACE TABLE fact_weather_day AS
SELECT
    UUID_STRING() AS fact_weather_day_id,

  
    dl.location_id,
    dd.date_id,
    ddt.data_type_id,
    dg.granularity_id,

  
    s.time_init_utc,

  
    s.avg_temperature_air_2m_f        AS temperature_air_f,
    s.avg_temperature_feelslike_2m_f  AS feels_like_temperature_f,
    s.tot_precipitation_in            AS precipitation_in,
    s.tot_snowfall_in                 AS snowfall_in,
    s.avg_wind_speed_10m_mph           AS wind_speed_mph,
    s.avg_humidity_relative_2m_pct     AS humidity_pct,
    s.avg_pressure_mean_sea_level_mb  AS pressure_mb,
    s.avg_cloud_cover_tot_pct          AS cloud_cover_pct,
    s.avg_radiation_solar_total_wpm2   AS solar_radiation_wpm2,

    
    s.avg_temperature_air_2m_f
      - LAG(s.avg_temperature_air_2m_f) OVER (
            PARTITION BY dl.location_id, ddt.data_type_id
            ORDER BY dd.date
        ) AS day_temperature_change

FROM forecast_day_staging s
LEFT JOIN dim_time dt
  ON TO_VARCHAR(s.TIME_INIT_UTC, 'HH24MI') = dt.time_id
JOIN dim_location dl
  ON s.postal_code = dl.postal_code
 AND s.country     = dl.country

JOIN dim_date dd
  ON s.date_valid_std = dd.date

JOIN dim_data_type ddt
  ON ddt.data_type = 'day';




SELECT * FROM fact_weather
ORDER BY day_temperature_change asc
limit 10;