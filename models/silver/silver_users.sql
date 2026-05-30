-- =============================================================
-- Silver Model: silver_users
-- Author: Nicolas Gonzalez
-- Description: Cleans and validates raw user data from Bronze.
--              Casts data types, standardizes text fields,
--              and removes invalid records.
-- Source: REEL_DB.BRONZE.USERS
-- Target: REEL_DB.SILVER.SILVER_USERS
-- =============================================================

WITH bronze_users AS (
    -- Pull raw data from Bronze layer
    -- Everything is TEXT here — Bronze rule
    SELECT * FROM REEL_DB.BRONZE.USERS
),

cleaned AS (
    SELECT
        -- Cast UUID from text to proper string format
        TRIM(USER_ID)                           AS user_id,

        -- Standardize email to lowercase
        LOWER(TRIM(EMAIL))                      AS email,

        -- Clean display name
        TRIM(DISPLAY_NAME)                      AS display_name,

        -- Standardize state and city
        INITCAP(TRIM(STATE))                    AS state,
        INITCAP(TRIM(CITY))                     AS city,

        -- Cast timestamps from text to proper timestamp
        TRY_TO_TIMESTAMP(CREATED_AT)            AS created_at,
        TRY_TO_TIMESTAMP(UPDATED_AT)            AS updated_at,

        -- Add Silver metadata
        CURRENT_TIMESTAMP()                     AS _silver_loaded_at,
        'bronze_users'                          AS _silver_source

    FROM bronze_users

    -- Remove records with missing critical fields
    WHERE USER_ID IS NOT NULL
      AND EMAIL IS NOT NULL
      AND DISPLAY_NAME IS NOT NULL
)

SELECT * FROM cleaned
