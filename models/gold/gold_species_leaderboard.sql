-- =============================================================
-- Gold Model: gold_species_leaderboard
-- Author: Nicolas Gonzalez
-- Description: Ranks Florida fish species by total catches,
--              average size, average weight, and AI
--              identification rate. Powers the species
--              leaderboard KPI in Power BI dashboard.
-- =============================================================

WITH catches AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_CATCHES
),

species AS (
    SELECT * FROM REEL_DB.SILVER.SILVER_SPECIES
),

species_stats AS (
    SELECT
        s.species_id,
        s.common_name,
        s.scientific_name,
        s.habitat,
        s.native_to_fl,

        -- Catch volume metrics
        COUNT(c.catch_id)                           AS total_catches,
        COUNT(DISTINCT c.user_id)                   AS unique_anglers,
        COUNT(DISTINCT c.session_id)                AS sessions_with_species,

        -- Size metrics
        ROUND(AVG(c.length_inches), 2)              AS avg_length_inches,
        ROUND(MAX(c.length_inches), 2)              AS max_length_inches,
        ROUND(AVG(c.weight_lbs), 2)                 AS avg_weight_lbs,
        ROUND(MAX(c.weight_lbs), 2)                 AS max_weight_lbs,

        -- Behavior metrics
        ROUND(AVG(CASE WHEN c.was_released = TRUE
            THEN 1.0 ELSE 0.0 END) * 100, 2)        AS release_rate_pct,

        -- AI identification metrics
        ROUND(AVG(CASE WHEN c.ai_identified = TRUE
            THEN 1.0 ELSE 0.0 END) * 100, 2)        AS ai_id_rate_pct,
        ROUND(AVG(CASE WHEN c.ai_identified = TRUE
            THEN c.ai_confidence_score END), 3)      AS avg_ai_confidence,

        -- Compliance metrics
        ROUND(AVG(CASE WHEN c.regulation_compliant = TRUE
            THEN 1.0 ELSE 0.0 END) * 100, 2)        AS compliance_rate_pct,

        CURRENT_TIMESTAMP()                         AS _gold_loaded_at

    FROM species s
    LEFT JOIN catches c ON s.species_id = c.species_id
    GROUP BY
        s.species_id,
        s.common_name,
        s.scientific_name,
        s.habitat,
        s.native_to_fl
)

SELECT
    -- Add rank by total catches
    RANK() OVER (
        ORDER BY total_catches DESC
    )                                               AS catch_rank,
    *
FROM species_stats
ORDER BY catch_rank