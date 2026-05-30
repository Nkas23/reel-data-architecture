-- =============================================================
-- Gold Model: gold_conversion_funnel
-- Author: Nicolas Gonzalez
-- Description: Computes free to paid conversion rate and
--              average days to convert per cohort month.
--              Powers the conversion funnel KPI in Power BI.
-- =============================================================

WITH subscriptions AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_SUBSCRIPTIONS
),

users AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_USERS
),

-- Get each user's first free subscription date
free_subs AS (
    SELECT
        user_id,
        MIN(started_at)                             AS free_started_at
    FROM subscriptions
    WHERE tier = 'free'
    GROUP BY user_id
),

-- Get each user's first paid subscription date
paid_subs AS (
    SELECT
        user_id,
        MIN(started_at)                             AS paid_started_at,
        tier                                        AS paid_tier,
        price_usd                                   AS paid_price
    FROM subscriptions
    WHERE tier IN ('standard', 'pro')
    GROUP BY user_id, tier, price_usd
),

-- Join to compute conversion metrics
conversion AS (
    SELECT
        u.user_id,
        DATE_TRUNC('month', f.free_started_at)      AS cohort_month,
        f.free_started_at,
        p.paid_started_at,
        p.paid_tier,
        p.paid_price,
        CASE WHEN p.user_id IS NOT NULL
             THEN TRUE ELSE FALSE
        END                                         AS did_convert,
        DATEDIFF('day',
            f.free_started_at,
            p.paid_started_at)                      AS days_to_convert
    FROM users u
    LEFT JOIN free_subs f ON u.user_id = f.user_id
    LEFT JOIN paid_subs p ON u.user_id = p.user_id
),

aggregated AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id)                     AS total_users,
        COUNT(DISTINCT CASE
            WHEN did_convert = TRUE
            THEN user_id END)                       AS converted_users,
        ROUND(COUNT(DISTINCT CASE
            WHEN did_convert = TRUE
            THEN user_id END) * 100.0
            / NULLIF(COUNT(DISTINCT user_id), 0)
            , 2)                                    AS conversion_rate_pct,
        ROUND(AVG(CASE
            WHEN did_convert = TRUE
            THEN days_to_convert END), 1)           AS avg_days_to_convert,
        COUNT(DISTINCT CASE
            WHEN paid_tier = 'standard'
            THEN user_id END)                       AS converted_to_standard,
        COUNT(DISTINCT CASE
            WHEN paid_tier = 'pro'
            THEN user_id END)                       AS converted_to_pro
    FROM conversion
    GROUP BY cohort_month
)

SELECT
    cohort_month,
    total_users,
    converted_users,
    conversion_rate_pct,
    avg_days_to_convert,
    converted_to_standard,
    converted_to_pro,
    CURRENT_TIMESTAMP()                             AS _gold_loaded_at
FROM aggregated
ORDER BY cohort_month