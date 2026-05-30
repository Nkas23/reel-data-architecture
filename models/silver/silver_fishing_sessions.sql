-- =============================================================
-- Silver Model: silver_fishing_sessions
-- Author: Nicolas Gonzalez
-- Description: Cleans fishing session data from Bronze.
--              Casts timestamps, validates coordinates,
--              computes session duration, and filters out
--              incomplete sessions (no end time).
--              This model powers regional activity analytics.
-- Source: REEL_DB.BRONZE.FISHING_SESSIONS
-- Target: REEL_DB.SILVER.SILVER_FISHING_SESSIONS
-- =============================================================

WITH bronze_sessions AS (
    SELECT * FROM REEL_DB.BRONZE.FISHING_SESSIONS
),

cleaned AS (
    SELECT
        TRIM(SESSION_ID)                            AS session_id,
        TRIM(USER_ID)                               AS user_id,

        -- Cast timestamps
        TRY_TO_TIMESTAMP(STARTED_AT)                AS started_at,
        TRY_TO_TIMESTAMP(ENDED_AT)                  AS ended_at,

        -- Compute duration in minutes from timestamps
        -- Bronze duration_minutes was a computed column
        -- we recompute here for Silver validation
        DATEDIFF('minute',
            TRY_TO_TIMESTAMP(STARTED_AT),
            TRY_TO_TIMESTAMP(ENDED_AT)
        )                                           AS duration_minutes,

        -- Standardize location fields
        TRIM(LOCATION_NAME)                         AS location_name,
        LOWER(TRIM(WATER_BODY_TYPE))                AS water_body_type,
        INITCAP(TRIM(COUNTY))                       AS county,
        LOWER(TRIM(WEATHER))                        AS weather,
        TRIM(NOTES)                                 AS notes,

        -- Flag sessions by duration bucket
        CASE
            WHEN DATEDIFF('minute',
                TRY_TO_TIMESTAMP(STARTED_AT),
                TRY_TO_TIMESTAMP(ENDED_AT)) < 60
            THEN 'short'
            WHEN DATEDIFF('minute',
                TRY_TO_TIMESTAMP(STARTED_AT),
                TRY_TO_TIMESTAMP(ENDED_AT)) < 180
            THEN 'medium'
            ELSE 'long'
        END                                         AS session_length_bucket,

        -- Extract date parts for time-based analytics
        DATE(TRY_TO_TIMESTAMP(STARTED_AT))          AS session_date,
        DAYOFWEEK(TRY_TO_TIMESTAMP(STARTED_AT))     AS day_of_week,
        MONTH(TRY_TO_TIMESTAMP(STARTED_AT))         AS session_month,
        YEAR(TRY_TO_TIMESTAMP(STARTED_AT))          AS session_year,

        -- Silver metadata
        CURRENT_TIMESTAMP()                         AS _silver_loaded_at,
        'bronze_fishing_sessions'                   AS _silver_source

    FROM bronze_sessions

    -- Only include completed sessions
    WHERE SESSION_ID IS NOT NULL
      AND USER_ID IS NOT NULL
      AND STARTED_AT IS NOT NULL
      AND ENDED_AT IS NOT NULL
)

SELECT * FROM cleaned