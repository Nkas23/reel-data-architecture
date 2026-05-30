-- =============================================================
-- Silver Model: silver_species
-- Author: Nicolas Gonzalez
-- Description: Cleans species reference data from Bronze.
--              Standardizes names and habitat values.
--              This is a dimension model — data rarely changes.
--              Powers the species leaderboard Gold model.
-- Source: REEL_DB.BRONZE.SPECIES
-- Target: REEL_DB.SILVER.SILVER_SPECIES
-- =============================================================

WITH bronze_species AS (
    SELECT * FROM REEL_DB.BRONZE.SPECIES
),

cleaned AS (
    SELECT
        TRIM(SPECIES_ID)                            AS species_id,

        -- Standardize common name to title case
        INITCAP(TRIM(COMMON_NAME))                  AS common_name,

        -- Keep scientific name as-is (proper noun)
        TRIM(SCIENTIFIC_NAME)                       AS scientific_name,

        -- Standardize habitat to lowercase
        LOWER(TRIM(HABITAT))                        AS habitat,

        -- Cast boolean
        CASE WHEN UPPER(TRIM(NATIVE_TO_FL)) = 'TRUE'
             THEN TRUE ELSE FALSE
        END                                         AS native_to_fl,

        TRY_TO_TIMESTAMP(CREATED_AT)                AS created_at,

        -- Silver metadata
        CURRENT_TIMESTAMP()                         AS _silver_loaded_at,
        'bronze_species'                            AS _silver_source

    FROM bronze_species

    WHERE SPECIES_ID IS NOT NULL
      AND COMMON_NAME IS NOT NULL
)

SELECT * FROM cleaned