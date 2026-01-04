WITH customer_traffic_model AS (
    SELECT 
        dt.hour,
        dd.day,
        f.temperature_air_f,
        f.precipitation_in,
        f.cloud_cover_pct,
        -- Model návštevnosti: príjemné počasie = viac zákazníkov
        CASE 
            WHEN f.temperature_air_f BETWEEN 65 AND 80 AND f.precipitation_in = 0 THEN 100
            WHEN f.temperature_air_f BETWEEN 55 AND 85 AND f.precipitation_in < 0.1 THEN 80
            WHEN f.precipitation_in > 0.2 THEN 40
            WHEN f.temperature_air_f < 40 OR f.temperature_air_f > 90 THEN 50
            ELSE 70
        END AS expected_footfall_index,
        CASE 
            WHEN f.precipitation_in > 0 THEN 'Dazd'
            WHEN f.cloud_cover_pct > 70 THEN 'Zamracene'
            ELSE 'Pekne'
        END AS weather_category
    FROM fact_weather_hour f
    JOIN dim_time dt ON f.time_id = dt.time_id
    JOIN dim_date dd ON f.date_id = dd.date_id
    JOIN dim_data_type ddt ON f.data_type_id = ddt.data_type_id
    WHERE ddt.data_type = 'measurement'
)
SELECT 
    LPAD(hour::VARCHAR, 2, '0') || ':00' AS hodina,
    ROUND(AVG(expected_footfall_index), 0) AS ocakavana_navstevnost_index,
    ROUND(AVG(temperature_air_f), 1) AS priemerna_teplota_f,
    ROUND(COUNT(CASE WHEN weather_category = 'Pekne' THEN 1 END) * 100.0 / COUNT(*), 1) AS percento_pekneho_pocasia,
    COUNT(*) AS pocet_hodin
FROM customer_traffic_model
GROUP BY hour
ORDER BY hour ASC;