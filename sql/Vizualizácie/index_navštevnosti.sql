WITH customer_traffic_conditions AS (
    SELECT 
        dl.country,
        dt.hour,
        dd.day,
        f.temperature_air_f,
        f.precipitation_in,
        f.cloud_cover_pct,
        f.humidity_pct,

        
        CASE 
            WHEN f.temperature_air_f < 40 OR f.temperature_air_f > 92 THEN 40
            WHEN f.temperature_air_f < 50 OR f.temperature_air_f > 88 THEN 25
            WHEN f.temperature_air_f < 55 OR f.temperature_air_f > 85 THEN 10
            ELSE 0
        END AS temp_penalty,

        
        CASE 
            WHEN f.precipitation_in > 0.2 THEN 40
            WHEN f.precipitation_in > 0.1 THEN 25
            WHEN f.precipitation_in > 0.05 THEN 10
            ELSE 0
        END AS rain_penalty,

        
        CASE 
            WHEN f.cloud_cover_pct > 80 THEN 15
            WHEN f.cloud_cover_pct > 50 THEN 5
            ELSE 0
        END AS cloud_penalty,

        
        CASE 
            WHEN f.precipitation_in > 0.1 THEN 'Dazd'
            WHEN f.cloud_cover_pct > 70 THEN 'Zamracene'
            WHEN f.temperature_air_f < 50 OR f.temperature_air_f > 85 THEN 'Extremne'
            ELSE 'Pekne'
        END AS weather_category

    FROM fact_weather_hour f
    JOIN dim_time dt ON f.time_id = dt.time_id
    JOIN dim_location dl ON f.location_id = dl.location_id
    JOIN dim_date dd ON f.date_id = dd.date_id
    JOIN dim_data_type ddt ON f.data_type_id = ddt.data_type_id
    WHERE ddt.data_type = 'measurement'
)

SELECT 
    country AS krajina,

    
    GREATEST(
        0,
        ROUND(
            100 - AVG(
                temp_penalty +
                rain_penalty +
                cloud_penalty
            ),
            0
        )
    ) AS ocakavana_navstevnost_index,

    ROUND(AVG(temperature_air_f), 1) AS priemerna_teplota_f,
    ROUND(AVG(cloud_cover_pct), 0) AS priemerna_oblacnost_pct,

    ROUND(
        COUNT(CASE WHEN weather_category = 'Pekne' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) AS percento_idealneho_pocasia,

    ROUND(
        COUNT(CASE WHEN weather_category = 'Dazd' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) AS percento_dazda,

    ROUND(
        COUNT(CASE WHEN weather_category = 'Extremne' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) AS percento_extremov,

    COUNT(*) AS pocet_hodin,
    COUNT(DISTINCT day) AS pocet_dni

FROM customer_traffic_conditions
GROUP BY country
HAVING COUNT(*) > 1000
ORDER BY ocakavana_navstevnost_index DESC;