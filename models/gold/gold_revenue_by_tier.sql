-- =============================================================
-- Gold Model: gold_revenue_by_tier
-- Author: Nicolas Gonzalez
-- Description: Computes Monthly Recurring Revenue (MRR)
--              broken down by subscription tier.
--              Standard = $4.99/month, Pro = $9.99/month.
--              Powers the revenue KPI in Power BI dashboard.
-- =============================================================

WITH subscriptions AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_SUBSCRIPTIONS
),

monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', started_at)             AS revenue_month,
        tier,
        price_usd,
        COUNT(DISTINCT user_id)                     AS active_subscribers,

        -- Monthly Recurring Revenue per tier
        ROUND(COUNT(DISTINCT user_id)
            * price_usd, 2)                         AS mrr,

        CURRENT_TIMESTAMP()                         AS _gold_loaded_at

    FROM subscriptions

    -- Only count active paid subscriptions
    WHERE is_currently_active = TRUE
      AND tier IN ('standard', 'pro')

    GROUP BY
        DATE_TRUNC('month', started_at),
        tier,
        price_usd
),

-- Add total MRR across all tiers per month
with_totals AS (
    SELECT
        revenue_month,
        tier,
        price_usd,
        active_subscribers,
        mrr,
        SUM(mrr) OVER (
            PARTITION BY revenue_month
        )                                           AS total_mrr_that_month,
        ROUND(mrr * 100.0 / NULLIF(
            SUM(mrr) OVER (PARTITION BY revenue_month)
        , 0), 2)                                    AS pct_of_total_mrr,
        _gold_loaded_at
    FROM monthly_revenue
)

SELECT * FROM with_totals
ORDER BY revenue_month, tier