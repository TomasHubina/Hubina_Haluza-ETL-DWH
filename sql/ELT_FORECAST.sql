USE DATABASE CHEETAH_DB;
USE WAREHOUSE CHEETAH_WH;

CREATE OR replace SCHEMA LabProjekt;
USE SCHEMA LabProjekt;

DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_DAY;
DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_HISTORY_DAY;
DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_HISTORY_HOUR;
DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_HOUR;
DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.POSTAL_CODES;
DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.HISTORY_DAY;
DESCRIBE table WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.HISTORY_HOUR;

---------------ELT---------------
---------STAGING TABUĽKY---------

--Tabuľka lokalít, v ktorých prebiehajú merania počasia.
--Z neskorších kapacitných obmedzení sa odfiltrovali niektoré mestá a krajiny
CREATE OR REPLACE TABLE postal_codes_staging AS
SELECT
    POSTAL_CODE,
    CITY_NAME,
    COUNTRY
FROM (
    SELECT distinct
        POSTAL_CODE,
        CITY_NAME,
        COUNTRY,
        ROW_NUMBER() OVER (
            PARTITION BY COUNTRY
            ORDER BY POSTAL_CODE
        ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.POSTAL_CODES
    where COUNTRY NOT IN ('GB', 'BR', 'CA', 'JP', 'US', 'ZA', 'IN', 'JE', 'DE', 'MC')
)
WHERE rn = 1;

SELECT COUNT(*) FROM postal_codes_staging;

--Tabuľka predpovedí počasia na aktuálny deň, filtrovaná z kapacitných obmedzení len na prvú predpoveď a lokality, ktoré sme si vyfiltrovali 
 CREATE OR REPLACE TABLE forecast_day_staging AS
SELECT *
FROM (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.city_name, f.country, f.date_valid_std
            ORDER BY f.time_init_utc
        ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_DAY f
    JOIN postal_codes_staging p
        ON f.postal_code = p.postal_code
       AND f.country = p.country
)
WHERE rn = 1;

SELECT COUNT(*) FROM forecast_day_staging;

---Tabuľka záznamov historických predpovedí pre dni, filtrovaná podobne ako tabuľka vyššie a podľa časového intervalu
CREATE OR REPLACE TABLE forecast_history_day_staging AS
SELECT *
    FROM (
        SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.city_name, f.country, f.date_valid_std
            ORDER BY f.time_init_utc
        ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_HISTORY_DAY f
    JOIN postal_codes_staging p
        ON f.postal_code = p.postal_code
        AND f.country = p.country
    WHERE f.time_init_utc >= DATE '2025-10-01'
    AND f.time_init_utc <  DATE '2026-01-01'
)
WHERE rn = 1;

-- Tabuľka skutočných nameraných hodnôt v priebehu dní
CREATE OR REPLACE TABLE history_day_staging AS
SELECT *
FROM (
    SELECT
    f.*,
    ROW_NUMBER() OVER (
        PARTITION BY f.city_name, f.country, f.date_valid_std
        ORDER BY f.date_valid_std
    ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.HISTORY_DAY f
    JOIN postal_codes_staging p
    ON f.postal_code = p.postal_code
    AND f.country = p.country
    WHERE f.date_valid_std >= DATE '2025-10-01'
    AND f.date_valid_std <  DATE '2026-01-01'
)
WHERE rn = 1;

SELECT COUNT(*) FROM history_day_staging;

--Tabuľka skutočných nameraných hodnôt v priebehu hodín
CREATE OR REPLACE TABLE history_hour_staging AS
SELECT *
FROM (
    SELECT
    h.*,
    ROW_NUMBER() OVER (
        PARTITION BY h.city_name, h.country, h.time_valid_utc
        ORDER BY h.time_valid_utc
    ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.HISTORY_HOUR h
    JOIN postal_codes_staging p
    ON h.postal_code = p.postal_code
    AND h.country = p.country
    WHERE h.time_valid_utc >= DATE '2025-10-01'
    AND h.time_valid_utc <  DATE '2026-01-01'
)
WHERE rn = 1;

SELECT COUNT(*) FROM history_hour_staging;

--Tabuľka predpovedí počasia v priebehu hodín v aktuálny deň
CREATE OR REPLACE TABLE forecast_hour_staging AS
SELECT *
FROM (
    SELECT
    f.*,
    ROW_NUMBER() OVER (
        PARTITION BY f.city_name, f.country, f.time_valid_utc
        ORDER BY f.time_init_utc
    ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_HOUR f
    JOIN postal_codes_staging p
    ON f.postal_code = p.postal_code
    AND f.country = p.country
)
WHERE rn = 1;

SELECT COUNT(*) FROM forecast_hour_staging;

-- História predpovedí podľa hodiny filtrovaná podľa určitých miest a posledných 90 dní
CREATE OR REPLACE TABLE forecast_history_hour_staging AS
SELECT *
FROM (
    SELECT
    f.*,
    ROW_NUMBER() OVER (
        PARTITION BY f.city_name, f.country, f.time_valid_utc
        ORDER BY f.time_init_utc DESC
    ) AS rn
    FROM WEATHER_SOURCE_LLC_FROSTBYTE.ONPOINT_ID.FORECAST_HISTORY_HOUR f
    JOIN postal_codes_staging p
      ON f.postal_code = p.postal_code
     AND f.country = p.country
    WHERE f.time_init_utc >= DATE '2025-10-01'
    AND f.time_init_utc <  DATE '2026-01-01'
)
WHERE rn = 1;

SELECT COUNT(*) FROM forecast_history_hour_staging;
