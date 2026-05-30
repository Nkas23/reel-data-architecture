-- =============================================================
-- Silver Model: silver_social_posts
-- Author: Nicolas Gonzalez
-- Description: Cleans social post data from Bronze.
--              Casts engagement counters to numeric,
--              standardizes boolean fields, and filters
--              out private posts from analytics.
--              Powers engagement metrics in Gold layer.
-- Source: REEL_DB.BRONZE.SOCIAL_POSTS
-- Target: REEL_DB.SILVER.SILVER_SOCIAL_POSTS
-- =============================================================

WITH bronze_posts AS (
    SELECT * FROM REEL_DB.BRONZE.SOCIAL_POSTS
),

cleaned AS (
    SELECT
        TRIM(POST_ID)                               AS post_id,
        TRIM(USER_ID)                               AS user_id,
        TRIM(CATCH_ID)                              AS catch_id,
        TRIM(SESSION_ID)                            AS session_id,

        -- Clean caption text
        TRIM(CAPTION)                               AS caption,

        -- Cast engagement counters to integer
        TRY_TO_NUMBER(LIKES_COUNT)                  AS likes_count,
        TRY_TO_NUMBER(COMMENTS_COUNT)               AS comments_count,

        -- Total engagement score
        TRY_TO_NUMBER(LIKES_COUNT) +
        TRY_TO_NUMBER(COMMENTS_COUNT)               AS total_engagement,

        -- Cast boolean
        CASE WHEN UPPER(TRIM(IS_PUBLIC)) = 'TRUE'
             THEN TRUE ELSE FALSE
        END                                         AS is_public,

        -- Cast timestamps
        TRY_TO_TIMESTAMP(POSTED_AT)                 AS posted_at,
        TRY_TO_TIMESTAMP(CREATED_AT)                AS created_at,

        -- Extract date parts
        DATE(TRY_TO_TIMESTAMP(POSTED_AT))           AS post_date,
        MONTH(TRY_TO_TIMESTAMP(POSTED_AT))          AS post_month,
        YEAR(TRY_TO_TIMESTAMP(POSTED_AT))           AS post_year,

        -- Silver metadata
        CURRENT_TIMESTAMP()                         AS _silver_loaded_at,
        'bronze_social_posts'                       AS _silver_source

    FROM bronze_posts

    -- Only include public posts in analytics
    WHERE POST_ID IS NOT NULL
      AND USER_ID IS NOT NULL
      AND UPPER(TRIM(IS_PUBLIC)) = 'TRUE'
)

SELECT * FROM cleaned