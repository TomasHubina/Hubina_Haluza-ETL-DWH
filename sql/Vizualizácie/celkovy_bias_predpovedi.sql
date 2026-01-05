--Celkový bias predpovedí počasia
SELECT
    AVG(predpoved_tep - meranie_temp) AS celkovy_bias_predpovedi
FROM (
    SELECT
        f.temperature_air_f AS predpoved_tep,
        m.temperature_air_f AS meranie_temp
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
);
