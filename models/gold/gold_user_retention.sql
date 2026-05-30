-- =============================================================
-- Gold Model: gold_user_retention
-- Author: Nicolas Gonzalez
-- Description: Computes Day 7 and Day 30 user retention rates
--              by cohort month. Retention = users who had at
--              least one fishing session after signup.
--              Powers the retention KPI in Power BI dashboard.
-- =============================================================

WITH users AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_USERS
),

sessions AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_FISHING_SESSIONS
),

user_sessions AS (
    SELECT
        u.user_id,
        u.created_at                                AS signup_date,
        DATE_TRUNC('month', u.created_at)           AS cohort_month,
        MIN(s.started_at)                           AS first_session_date,
        DATEDIFF('day', u.created_at,
            MIN(s.started_at))                      AS days_to_first_session
    FROM users u
    LEFT JOIN sessions s ON u.user_id = s.user_id
    GROUP BY u.user_id, u.created_at
),

retention AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id)                     AS total_users,

        -- Day 7 retention
        COUNT(DISTINCT CASE
            WHEN days_to_first_session <= 7
            THEN user_id END)                       AS retained_day_7,

        -- Day 30 retention
        COUNT(DISTINCT CASE
            WHEN days_to_first_session <= 30
            THEN user_id END)                       AS retained_day_30,

        -- Retention rates
        ROUND(COUNT(DISTINCT CASE
            WHEN days_to_first_session <= 7
            THEN user_id END) * 100.0
            / NULLIF(COUNT(DISTINCT user_id), 0), 2) AS retention_rate_day_7,

        ROUND(COUNT(DISTINCT CASE
            WHEN days_to_first_session <= 30
            THEN user_id END) * 100.0
            / NULLIF(COUNT(DISTINCT user_id), 0), 2) AS retention_rate_day_30

    FROM user_sessions
    GROUP BY cohort_month
)

SELECT
    cohort_month,
    total_users,
    retained_day_7,
    retained_day_30,
    retention_rate_day_7,
    retention_rate_day_30,
    CURRENT_TIMESTAMP()                             AS _gold_loaded_at
FROM retention
ORDER BY cohort_month