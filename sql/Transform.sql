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
    SELECT DATE_VALID_STD AS d FROM forecast_day_staging
    UNION
    SELECT DATE_VALID_STD FROM history_day_staging
    UNION
    SELECT DATE_VALID_STD FROM forecast_history_day_staging
);


--TOTO JE PLATNE
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


--TOTO JE PLATNE
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

FROM (
    SELECT
        postal_code,
        country,
        date_valid_std,
        time_init_utc,
        avg_temperature_air_2m_f,
        avg_temperature_feelslike_2m_f,
        tot_precipitation_in,
        tot_snowfall_in,
        avg_wind_speed_10m_mph,
        avg_humidity_relative_2m_pct,
        avg_pressure_mean_sea_level_mb,
        avg_cloud_cover_tot_pct,
        avg_radiation_solar_total_wpm2,
        'forecast' AS data_type
    FROM forecast_day_staging
    UNION ALL
    SELECT
        postal_code,
        country,
        date_valid_std,
        time_init_utc,
        avg_temperature_air_2m_f,
        avg_temperature_feelslike_2m_f,
        tot_precipitation_in,
        tot_snowfall_in,
        avg_wind_speed_10m_mph,
        avg_humidity_relative_2m_pct,
        avg_pressure_mean_sea_level_mb,
        avg_cloud_cover_tot_pct,
        avg_radiation_solar_total_wpm2,
        'forecast' AS data_type
    FROM forecast_history_day_staging
    UNION ALL
    SELECT
        postal_code,
        country,
        date_valid_std,
        NULL AS time_init_utc,
        avg_temperature_air_2m_f,
        avg_temperature_feelslike_2m_f,
        tot_precipitation_in,
        tot_snowfall_in,
        avg_wind_speed_10m_mph,
        avg_humidity_relative_2m_pct,
        avg_pressure_mean_sea_level_mb,
        avg_cloud_cover_tot_pct,
        avg_radiation_solar_total_wpm2,
        'measurement' AS data_type
    FROM history_day_staging
) s

JOIN dim_location dl
  ON s.postal_code = dl.postal_code
 AND s.country     = dl.country

JOIN dim_date dd
  ON s.date_valid_std = dd.date

JOIN dim_data_type ddt
  ON ddt.data_type = s.data_type

JOIN dim_granularity dg
  ON dg.granularity = 'day';



CREATE OR REPLACE TABLE fact_weather_hour AS
WITH base_hour AS (

    
    SELECT
        postal_code,
        country,
        time_valid_utc,
        time_init_utc,
        temperature_air_2m_f        AS temperature_air_f,
        temperature_feelslike_2m_f  AS feels_like_temperature_f,
        precipitation_in,
        snowfall_in,
        wind_speed_10m_mph          AS wind_speed_mph,
        humidity_relative_2m_pct    AS humidity_pct,
        pressure_mean_sea_level_mb AS pressure_mb,
        cloud_cover_pct,
        radiation_solar_total_wpm2,
        'forecast'                  AS data_type
    FROM forecast_hour_staging
    WHERE time_init_utc >= DATEADD(day, -30, CURRENT_TIMESTAMP())

    UNION ALL

    
    SELECT
        postal_code,
        country,
        time_valid_utc,
        NULL                         AS time_init_utc,
        temperature_air_2m_f,
        temperature_feelslike_2m_f,
        precipitation_in,
        snowfall_in,
        wind_speed_10m_mph,
        humidity_relative_2m_pct,
        pressure_mean_sea_level_mb,
        cloud_cover_pct,
        radiation_solar_total_wpm2,
        'measurement'               AS data_type
    FROM history_hour_staging
    WHERE time_valid_utc >= DATEADD(day, -30, CURRENT_TIMESTAMP())
)

SELECT
    UUID_STRING() AS fact_weather_hour_id,

    dl.location_id,
    dd.date_id,
    dt.time_id,
    ddt.data_type_id,
    dg.granularity_id,

    b.time_init_utc,

    b.temperature_air_f,
    b.feels_like_temperature_f,
    b.precipitation_in,
    b.snowfall_in,
    b.wind_speed_mph,
    b.humidity_pct,
    b.pressure_mb,
    b.cloud_cover_pct,
    b.radiation_solar_total_wpm2,

   
    b.temperature_air_f
      - LAG(b.temperature_air_f) OVER (
            PARTITION BY dl.location_id, ddt.data_type_id, dd.date_id
            ORDER BY b.time_valid_utc
        ) AS hour_temperature_change

FROM base_hour b

JOIN dim_location dl
  ON b.postal_code = dl.postal_code
 AND b.country     = dl.country

JOIN dim_date dd
  ON CAST(b.time_valid_utc AS DATE) = dd.date

JOIN dim_time dt
  ON dt.time_utc = b.time_valid_utc   

JOIN dim_data_type ddt
  ON ddt.data_type = b.data_type

JOIN dim_granularity dg
  ON dg.granularity = 'hour';
