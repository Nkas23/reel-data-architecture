-- =============================================================
-- Silver Model: silver_gps_events
-- Author: Nicolas Gonzalez
-- Description: Cleans GPS event data from Bronze.
--              Casts coordinates to numeric, validates
--              that coordinates fall within Florida bounds,
--              and removes invalid pings.
--              Powers the regional heatmap Gold model.
-- Source: REEL_DB.BRONZE.GPS_EVENTS
-- Target: REEL_DB.SILVER.SILVER_GPS_EVENTS
-- =============================================================

WITH bronze_gps AS (
    SELECT * FROM REEL_DB.BRONZE.GPS_EVENTS
),

cleaned AS (
    SELECT
        TRIM(GPS_ID)                                AS gps_id,
        TRIM(SESSION_ID)                            AS session_id,
        TRIM(USER_ID)                               AS user_id,

        -- Cast coordinates to numeric
        TRY_TO_DECIMAL(LATITUDE, 9, 6)              AS latitude,
        TRY_TO_DECIMAL(LONGITUDE, 9, 6)             AS longitude,

        -- Cast accuracy
        TRY_TO_DECIMAL(ACCURACY_METERS, 6, 2)       AS accuracy_meters,

        -- Cast timestamp
        TRY_TO_TIMESTAMP(RECORDED_AT)               AS recorded_at,
        TRY_TO_TIMESTAMP(CREATED_AT)                AS created_at,

        -- Flag whether coordinates are within Florida bounds
        -- Florida lat: 24.5 to 31.0, lon: -87.6 to -80.0
        CASE
            WHEN TRY_TO_DECIMAL(LATITUDE, 9, 6)
                     BETWEEN 24.5 AND 31.0
             AND TRY_TO_DECIMAL(LONGITUDE, 9, 6)
                     BETWEEN -87.6 AND -80.0
            THEN TRUE
            ELSE FALSE
        END                                         AS is_within_florida,

        -- Silver metadata
        CURRENT_TIMESTAMP()                         AS _silver_loaded_at,
        'bronze_gps_events'                         AS _silver_source

    FROM bronze_gps

    WHERE GPS_ID IS NOT NULL
      AND SESSION_ID IS NOT NULL
      AND LATITUDE IS NOT NULL
      AND LONGITUDE IS NOT NULL
)

SELECT * FROM cleaned