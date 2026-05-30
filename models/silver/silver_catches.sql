-- =============================================================
-- Silver Model: silver_catches
-- Author: Nicolas Gonzalez
-- Description: Cleans catch data from Bronze.
--              Casts numeric measurements, validates AI
--              confidence scores, and flags regulation
--              compliance. Core model for species analytics
--              and the leaderboard Gold model.
-- Source: REEL_DB.BRONZE.CATCHES
-- Target: REEL_DB.SILVER.SILVER_CATCHES
-- =============================================================

WITH bronze_catches AS (
    SELECT * FROM REEL_DB.BRONZE.CATCHES
),

cleaned AS (
    SELECT
        TRIM(CATCH_ID)                              AS catch_id,
        TRIM(SESSION_ID)                            AS session_id,
        TRIM(USER_ID)                               AS user_id,
        TRIM(SPECIES_ID)                            AS species_id,

        -- Cast measurements from text to numeric
        TRY_TO_DECIMAL(LENGTH_INCHES, 5, 2)         AS length_inches,
        TRY_TO_DECIMAL(WEIGHT_LBS, 5, 2)            AS weight_lbs,

        -- Cast boolean fields
        CASE WHEN UPPER(TRIM(AI_IDENTIFIED)) = 'TRUE'
             THEN TRUE ELSE FALSE
        END                                         AS ai_identified,

        -- Cast AI confidence score
        TRY_TO_DECIMAL(AI_CONFIDENCE_SCORE, 4, 3)   AS ai_confidence_score,

        -- Bucket AI confidence into readable labels
        CASE
            WHEN TRY_TO_DECIMAL(AI_CONFIDENCE_SCORE, 4, 3) >= 0.90
            THEN 'high'
            WHEN TRY_TO_DECIMAL(AI_CONFIDENCE_SCORE, 4, 3) >= 0.70
            THEN 'medium'
            WHEN TRY_TO_DECIMAL(AI_CONFIDENCE_SCORE, 4, 3) IS NOT NULL
            THEN 'low'
            ELSE 'not_identified'
        END                                         AS ai_confidence_bucket,

        -- Cast boolean fields
        CASE WHEN UPPER(TRIM(WAS_RELEASED)) = 'TRUE'
             THEN TRUE ELSE FALSE
        END                                         AS was_released,

        CASE WHEN UPPER(TRIM(REGULATION_COMPLIANT)) = 'TRUE'
             THEN TRUE ELSE FALSE
        END                                         AS regulation_compliant,

        TRIM(PHOTO_URL)                             AS photo_url,

        -- Cast timestamp
        TRY_TO_TIMESTAMP(CAUGHT_AT)                 AS caught_at,
        TRY_TO_TIMESTAMP(CREATED_AT)                AS created_at,

        -- Extract date parts
        DATE(TRY_TO_TIMESTAMP(CAUGHT_AT))           AS catch_date,
        MONTH(TRY_TO_TIMESTAMP(CAUGHT_AT))          AS catch_month,
        YEAR(TRY_TO_TIMESTAMP(CAUGHT_AT))           AS catch_year,

        -- Silver metadata
        CURRENT_TIMESTAMP()                         AS _silver_loaded_at,
        'bronze_catches'                            AS _silver_source

    FROM bronze_catches

    WHERE CATCH_ID IS NOT NULL
      AND SESSION_ID IS NOT NULL
      AND USER_ID IS NOT NULL
)

SELECT * FROM cleaned