-- =============================================================
-- Gold Model: gold_regional_activity
-- Author: Nicolas Gonzalez
-- Description: Aggregates fishing activity by Florida county.
--              Shows most active regions, average session
--              duration, total catches and species diversity
--              per county. Powers the regional heatmap
--              KPI in Power BI dashboard.
-- =============================================================

WITH sessions AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_FISHING_SESSIONS
),

catches AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_CATCHES
),

users AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_USERS
),

subscriptions AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_SUBSCRIPTIONS
),

-- Get current tier per user
current_tiers AS (
    SELECT DISTINCT
        user_id,
        FIRST_VALUE(tier) OVER (
            PARTITION BY user_id
            ORDER BY started_at DESC
        )                                           AS current_tier
    FROM subscriptions
    WHERE is_currently_active = TRUE
),

-- Aggregate session and catch data by county
county_stats AS (
    SELECT
        s.county,
        s.water_body_type,

        -- Session metrics
        COUNT(DISTINCT s.session_id)                AS total_sessions,
        COUNT(DISTINCT s.user_id)                   AS unique_anglers,
        ROUND(AVG(s.duration_minutes), 1)           AS avg_session_minutes,
        ROUND(SUM(s.duration_minutes) / 60.0, 1)   AS total_hours_fished,

        -- Catch metrics
        COUNT(DISTINCT c.catch_id)                  AS total_catches,
        COUNT(DISTINCT c.species_id)                AS species_diversity,
        ROUND(COUNT(DISTINCT c.catch_id) * 1.0
            / NULLIF(COUNT(DISTINCT s.session_id)
            , 0), 2)                                AS avg_catches_per_session,

        -- Weather breakdown
        COUNT(DISTINCT CASE
            WHEN s.weather = 'sunny'
            THEN s.session_id END)                  AS sunny_sessions,
        COUNT(DISTINCT CASE
            WHEN s.weather = 'cloudy'
            THEN s.session_id END)                  AS cloudy_sessions,
        COUNT(DISTINCT CASE
            WHEN s.weather = 'rainy'
            THEN s.session_id END)                  AS rainy_sessions,

        -- Subscription tier breakdown
        COUNT(DISTINCT CASE
            WHEN t.current_tier = 'pro'
            THEN s.user_id END)                     AS pro_anglers,
        COUNT(DISTINCT CASE
            WHEN t.current_tier = 'standard'
            THEN s.user_id END)                     AS standard_anglers,
        COUNT(DISTINCT CASE
            WHEN t.current_tier = 'free'
            THEN s.user_id END)                     AS free_anglers,

        CURRENT_TIMESTAMP()                         AS _gold_loaded_at

    FROM sessions s
    LEFT JOIN catches c ON s.session_id = c.session_id
    LEFT JOIN current_tiers t ON s.user_id = t.user_id
    WHERE s.county IS NOT NULL
    GROUP BY s.county, s.water_body_type
)

SELECT
    RANK() OVER (
        ORDER BY total_sessions DESC
    )                                               AS activity_rank,
    *
FROM county_stats
ORDER BY activity_rank