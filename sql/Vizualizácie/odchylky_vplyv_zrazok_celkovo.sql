--Ovplyvnenie predpovedí teplôt zrážkami
WITH paired AS (
    SELECT
        f.location_id,
        f.date_id,
        f.temperature_air_f AS predpoved_tep,
        m.temperature_air_f AS meranie_tep,
        m.precipitation_in
    FROM fact_weather_day f
    JOIN fact_weather_day m
      ON f.location_id = m.location_id
     AND f.date_id = m.date_id
    JOIN dim_data_type dt_f
      ON dt_f.data_type_id = f.data_type_id
     AND dt_f.data_type = 'forecast'
    JOIN dim_data_type dt_m
      ON dt_m.data_type_id = m.data_type_id
     AND dt_m.data_type = 'measurement'
)

SELECT
    CASE
        WHEN precipitation_in = 0 THEN 'bez_zrazok'
        ELSE 'so_zrazkami'
    END AS vyskyt_zrazok,

    AVG(ABS(predpoved_tep - meranie_tep)) AS priem_abs_odchylka_tep,
    COUNT(*) AS pocet_zaznamov
FROM paired
GROUP BY vyskyt_zrazok
ORDER BY vyskyt_zrazok;
