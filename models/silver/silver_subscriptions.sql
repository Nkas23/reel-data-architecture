-- =============================================================
-- Silver Model: silver_subscriptions
-- Author: Nicolas Gonzalez
-- Description: Cleans subscription data from Bronze.
--              Validates tier values, casts price to numeric,
--              and computes days to convert from free to paid.
--              This model powers the conversion funnel metrics.
-- Source: REEL_DB.BRONZE.SUBSCRIPTIONS
-- Target: REEL_DB.SILVER.SILVER_SUBSCRIPTIONS
-- =============================================================

WITH bronze_subscriptions AS (
    SELECT * FROM REEL_DB.BRONZE.SUBSCRIPTIONS
),

cleaned AS (
    SELECT
        TRIM(SUBSCRIPTION_ID)                       AS subscription_id,
        TRIM(USER_ID)                               AS user_id,

        -- Standardize tier to lowercase
        LOWER(TRIM(TIER))                           AS tier,

        -- Cast price from text to numeric
        TRY_TO_DECIMAL(PRICE_USD, 6, 2)             AS price_usd,

        -- Standardize status to lowercase
        LOWER(TRIM(STATUS))                         AS status,

        -- Cast timestamps
        TRY_TO_TIMESTAMP(STARTED_AT)                AS started_at,
        TRY_TO_TIMESTAMP(ENDED_AT)                  AS ended_at,
        TRY_TO_TIMESTAMP(CREATED_AT)                AS created_at,

        -- Compute subscription duration in days
        DATEDIFF('day',
            TRY_TO_TIMESTAMP(STARTED_AT),
            COALESCE(TRY_TO_TIMESTAMP(ENDED_AT), CURRENT_TIMESTAMP())
        )                                           AS duration_days,

        -- Flag currently active subscriptions
        CASE
            WHEN LOWER(TRIM(STATUS)) = 'active'
             AND ENDED_AT IS NULL
            THEN TRUE
            ELSE FALSE
        END                                         AS is_currently_active,

        -- Silver metadata
        CURRENT_TIMESTAMP()                         AS _silver_loaded_at,
        'bronze_subscriptions'                      AS _silver_source

    FROM bronze_subscriptions

    -- Remove invalid records
    WHERE SUBSCRIPTION_ID IS NOT NULL
      AND USER_ID IS NOT NULL
      AND TIER IN ('free', 'standard', 'pro')
)

SELECT * FROM cleaned