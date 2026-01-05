WITH productivity_conditions AS (
    SELECT 
        dl.country,
        dl.city_name,
        dt.hour,
        f.temperature_air_f,
        f.humidity_pct,
        f.wind_speed_mph,

       
        CASE 
            WHEN f.temperature_air_f < 40 OR f.temperature_air_f > 95 THEN 40
            WHEN f.temperature_air_f < 50 OR f.temperature_air_f > 85 THEN 25
            WHEN f.temperature_air_f < 60 OR f.temperature_air_f > 75 THEN 10
            ELSE 0
        END AS temp_penalty,

        
        CASE 
            WHEN f.humidity_pct < 20 OR f.humidity_pct > 70 THEN 25
            WHEN f.humidity_pct < 30 OR f.humidity_pct > 60 THEN 10
            ELSE 0
        END AS humidity_penalty,

        
        CASE 
            WHEN f.wind_speed_mph >= 20 THEN 25
            WHEN f.wind_speed_mph >= 10 THEN 10
            ELSE 0
        END AS wind_penalty

    FROM fact_weather_hour f
    JOIN dim_time dt ON f.time_id = dt.time_id
    JOIN dim_location dl ON f.location_id = dl.location_id
    JOIN dim_data_type ddt ON f.data_type_id = ddt.data_type_id
    WHERE ddt.data_type = 'measurement'
)

SELECT 
    CONCAT(country, ' - ', city_name) AS lokalita,

    
    GREATEST(
        0,
        ROUND(
            100 - AVG(
                temp_penalty +
                humidity_penalty +
                wind_penalty
            ),
            0
        )
    ) AS produktivny_index,

    ROUND(AVG(temperature_air_f), 1) AS priemerna_teplota_f,
    ROUND(AVG(humidity_pct), 0) AS priemerna_vlhkost_pct,
    ROUND(AVG(wind_speed_mph), 1) AS priemerna_rychlost_vetra_mph,

    COUNT(*) AS pocet_merani,
    COUNT(DISTINCT hour) AS pokrytie_hodin

FROM productivity_conditions
GROUP BY country, city_name
HAVING COUNT(*) > 1000
ORDER BY produktivny_index DESC;