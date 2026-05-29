 -- =============================================================
-- Reel App — Snowflake Setup Script
-- Author: Nicolas Gonzalez
-- Description: Creates the warehouse, database and three
--              Medallion layer schemas in Snowflake
-- =============================================================

CREATE WAREHOUSE IF NOT EXISTS REEL_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Reel app data pipeline warehouse';

CREATE DATABASE IF NOT EXISTS REEL_DB
    COMMENT = 'Reel fishing app — Medallion architecture database';

USE DATABASE REEL_DB;

CREATE SCHEMA IF NOT EXISTS REEL_DB.BRONZE
    COMMENT = 'Raw ingestion layer — exact copy of Supabase source tables';

CREATE SCHEMA IF NOT EXISTS REEL_DB.SILVER
    COMMENT = 'Cleaned and validated layer — dbt transformation models';

CREATE SCHEMA IF NOT EXISTS REEL_DB.GOLD
    COMMENT = 'Aggregated analytics layer — KPI and business metric models';
