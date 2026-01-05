WITH transport_conditions AS (
    SELECT 
        dl.country,
        dt.hour,
        -- Bezpečnostné faktory pre dopravu
        CASE WHEN f.precipitation_in > 0.05 THEN 30 ELSE 0 END AS wet_roads_penalty,
        CASE WHEN f.wind_speed_mph > 25 THEN 25 ELSE 0 END AS strong_wind_penalty,
        CASE WHEN f.cloud_cover_pct > 80 THEN 15 ELSE 0 END AS low_visibility_penalty,
        CASE WHEN f.temperature_air_f < 32 THEN 20 ELSE 0 END AS ice_risk_penalty,
        f.precipitation_in,
        f.wind_speed_mph,
        f.temperature_air_f
    FROM fact_weather_hour f
    JOIN dim_time dt ON f.time_id = dt.time_id
    JOIN dim_location dl ON f.location_id = dl.location_id
    JOIN dim_data_type ddt ON f.data_type_id = ddt.data_type_id
    WHERE ddt.data_type = 'measurement'
)
SELECT 
    country AS krajina,
    ROUND(100 - AVG(wet_roads_penalty + strong_wind_penalty + low_visibility_penalty + ice_risk_penalty), 0) AS bezpecnostny_index,
    ROUND(AVG(precipitation_in) * 100, 2) AS priemerne_zrazky_scaled,
    ROUND(AVG(wind_speed_mph), 1) AS priemerny_vietor_mph,
    ROUND(AVG(temperature_air_f), 1) AS priemerna_teplota_f,
    ROUND(SUM(CASE WHEN precipitation_in > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS percento_hodin_s_dazdom,
    COUNT(*) AS pocet_merani
FROM transport_conditions
GROUP BY country
HAVING COUNT(*) > 1000
ORDER BY bezpecnostny_index DESC;