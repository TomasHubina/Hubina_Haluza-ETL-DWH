-- ====================================================
-- STAR SCHEMA - WEATHER ANALYTICS (ERD / MODELING ONLY)
-- ====================================================

CREATE SCHEMA IF NOT EXISTS weather_dwh;
USE weather_dwh;

-- ====================================================
-- DIMENSION: LOCATION
-- ====================================================
CREATE TABLE DIM_LOCATION (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    postal_code VARCHAR(20),
    city_name VARCHAR(65),
    country CHAR(2)
);

-- ====================================================
-- DIMENSION: DATE
-- ====================================================
CREATE TABLE DIM_DATE (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    day INT,
    day_of_year INT
);

-- ====================================================
-- DIMENSION: TIME
-- ====================================================
CREATE TABLE DIM_TIME (
    time_id INT AUTO_INCREMENT PRIMARY KEY,
    hour_utc INT,
    is_daytime BOOLEAN
);

-- ====================================================
-- DIMENSION: WEATHER TYPE
-- ====================================================
CREATE TABLE DIM_WEATHER_TYPE (
    weather_type_id INT AUTO_INCREMENT PRIMARY KEY,
    data_type VARCHAR(20) -- HISTORY / FORECAST
);

-- ====================================================
-- DIMENSION: MEASUREMENT LEVEL
-- ====================================================
CREATE TABLE DIM_MEASUREMENT_LEVEL (
    measurement_level_id INT AUTO_INCREMENT PRIMARY KEY,
    level_description VARCHAR(50) -- 2M, 10M, 80M, 100M
);

-- ====================================================
-- FACT TABLE: WEATHER
-- ====================================================
CREATE TABLE FACT_WEATHER (
    fact_weather_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    location_id INT,
    date_id INT,
    time_id INT,
    weather_type_id INT,
    measurement_level_id INT,

    temperature_air_f DECIMAL(6,2),
    feels_like_temperature_f DECIMAL(6,2),
    precipitation_in DECIMAL(6,2),
    snowfall_in DECIMAL(6,2),
    wind_speed_mph DECIMAL(6,2),
    humidity_pct DECIMAL(6,2),
    pressure_mb DECIMAL(7,2),
    cloud_cover_pct DECIMAL(5,2),
    solar_radiation_wpm2 DECIMAL(8,2),

    CONSTRAINT fk_location
        FOREIGN KEY (location_id)
        REFERENCES DIM_LOCATION(location_id),

    CONSTRAINT fk_date
        FOREIGN KEY (date_id)
        REFERENCES DIM_DATE(date_id),

    CONSTRAINT fk_time
        FOREIGN KEY (time_id)
        REFERENCES DIM_TIME(time_id),

    CONSTRAINT fk_weather_type
        FOREIGN KEY (weather_type_id)
        REFERENCES DIM_WEATHER_TYPE(weather_type_id),
    CONSTRAINT fk_measurement_level
        FOREIGN KEY (measurement_level_id)
        REFERENCES DIM_MEASUREMENT_LEVEL(measurement_level_id)
);
