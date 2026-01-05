--Porovnanie predpovedí počasia oproti skutočnému meraniu
SELECT
    concat(l.country, ' - ', l.city_name) as lokalita,
    d.date as datum,
    ff.temperature_air_f AS predpoved_tep,
    fm.temperature_air_f AS meranie_tep,
    ff.temperature_air_f - fm.temperature_air_f AS odchylka
FROM fact_weather_day ff
JOIN fact_weather_day fm
  ON ff.location_id = fm.location_id
 AND ff.date_id = fm.date_id
JOIN dim_location l ON l.location_id = ff.location_id
JOIN dim_date d ON d.date_id = ff.date_id
WHERE ff.data_type_id = (
    SELECT data_type_id FROM dim_data_type WHERE data_type = 'forecast'
)
AND fm.data_type_id = (
    SELECT data_type_id FROM dim_data_type WHERE data_type = 'measurement'
);
