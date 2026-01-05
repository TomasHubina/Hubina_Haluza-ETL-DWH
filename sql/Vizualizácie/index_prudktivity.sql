WITH productivity_score AS (
    SELECT 
        dl.country,
        dt.hour,
        f.temperature_air_f,
        f.humidity_pct,
        f.wind_speed_mph,
        -- Optimálna teplota pre prácu: 60-75°F = 100 bodov
        CASE 
            WHEN f.temperature_air_f BETWEEN 60 AND 75 THEN 100
            WHEN f.temperature_air_f BETWEEN 50 AND 85 THEN 75
            WHEN f.temperature_air_f BETWEEN 40 AND 95 THEN 50
            ELSE 25
        END AS temp_score,
        -- Optimálna vlhkosť: 30-60% = 100 bodov
        CASE 
            WHEN f.humidity_pct BETWEEN 30 AND 60 THEN 100
            WHEN f.humidity_pct BETWEEN 20 AND 70 THEN 75
            ELSE 50
        END AS humidity_score,
        -- Optimálny vietor: <10 mph = 100 bodov
        CASE 
            WHEN f.wind_speed_mph < 10 THEN 100
            WHEN f.wind_speed_mph < 20 THEN 75
            ELSE 50
        END AS wind_score
    FROM fact_weather_hour f
    JOIN dim_time dt ON f.time_id = dt.time_id
    JOIN dim_location dl ON f.location_id = dl.location_id
    JOIN dim_data_type ddt ON f.data_type_id = ddt.data_type_id
    WHERE ddt.data_type = 'measurement'
)
SELECT 
    country AS krajina,
    ROUND(AVG((temp_score + humidity_score + wind_score) / 3.0), 0) AS produktivny_index,
    ROUND(AVG(temperature_air_f), 1) AS priemerna_teplota_f,
    ROUND(AVG(humidity_pct), 0) AS priemerna_vlhkost_pct,
    ROUND(AVG(wind_speed_mph), 1) AS priemerna_rychlost_vetra_mph,
    COUNT(*) AS pocet_merani,
    COUNT(DISTINCT hour) AS pokrytie_hodin
FROM productivity_score
GROUP BY country
HAVING COUNT(*) > 1000  -- Len krajiny s dostatočným počtom dát
ORDER BY produktivny_index DESC;