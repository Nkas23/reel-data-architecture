 -- =============================================================
-- REEL APP — PostgreSQL Schema for Supabase
-- Author: Nicolas Gonzalez
-- Description: Core operational database for the Reel fishing
--              app. Powers the Medallion architecture pipeline
--              (Bronze → Silver → Gold) for analytics.
-- =============================================================

-- -------------------------------------------------------------
-- 1. USERS
-- Stores every registered user and their subscription tier.
-- This is the root table — everything else connects to a user.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    display_name    VARCHAR(100) NOT NULL,
    state           VARCHAR(50),
    city            VARCHAR(100),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 2. SUBSCRIPTIONS
-- Tracks every subscription event per user — upgrades,
-- downgrades, cancellations. One user can have many records
-- over time. This powers the conversion funnel metrics.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id),
    tier            VARCHAR(20) NOT NULL CHECK (tier IN ('free', 'standard', 'pro')),
    price_usd       NUMERIC(6,2) NOT NULL,
    status          VARCHAR(20) NOT NULL CHECK (status IN ('active', 'cancelled', 'expired')),
    started_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at        TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 3. SPECIES
-- Master reference table for all fish species in the app.
-- Used for AI identification results and regulation lookups.
-- This is a lookup/dimension table — data rarely changes.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS species (
    species_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    common_name     VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(150),
    habitat         VARCHAR(50) CHECK (habitat IN ('freshwater', 'saltwater', 'both')),
    native_to_fl    BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 4. REGULATIONS
-- Florida fishing regulations per species — size limits,
-- bag limits, and seasonal closures. Powers the compliance
-- check feature in the Reel app.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS regulations (
    regulation_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    species_id      UUID NOT NULL REFERENCES species(species_id),
    region          VARCHAR(100) NOT NULL,
    min_size_inches NUMERIC(5,2),
    bag_limit       INTEGER,
    season_open     DATE,
    season_close    DATE,
    notes           TEXT,
    effective_date  DATE NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 5. FISHING SESSIONS
-- Every time a user starts a fishing trip in the app.
-- The central fact table — catches and GPS events both
-- connect to a session. Duration is computed on ingest.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fishing_sessions (
    session_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id),
    started_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at        TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER GENERATED ALWAYS AS (
                        EXTRACT(EPOCH FROM (ended_at - started_at)) / 60
                    ) STORED,
    location_name   VARCHAR(200),
    water_body_type VARCHAR(50) CHECK (water_body_type IN ('lake', 'river', 'ocean', 'bay', 'pond', 'canal')),
    county          VARCHAR(100),
    weather         VARCHAR(50),
    notes           TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 6. GPS EVENTS
-- Individual GPS coordinate pings during a session.
-- Powers the map trail feature and regional heatmaps.
-- High volume table — one session can have hundreds of rows.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gps_events (
    gps_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES fishing_sessions(session_id),
    user_id         UUID NOT NULL REFERENCES users(user_id),
    latitude        NUMERIC(9,6) NOT NULL,
    longitude       NUMERIC(9,6) NOT NULL,
    recorded_at     TIMESTAMP WITH TIME ZONE NOT NULL,
    accuracy_meters NUMERIC(6,2),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 7. CATCHES
-- Every fish caught and logged during a session.
-- Links to species for identification and regulations
-- for compliance checking. Core fact table for species
-- leaderboard and catch analytics.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS catches (
    catch_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES fishing_sessions(session_id),
    user_id             UUID NOT NULL REFERENCES users(user_id),
    species_id          UUID REFERENCES species(species_id),
    length_inches       NUMERIC(5,2),
    weight_lbs          NUMERIC(5,2),
    ai_identified       BOOLEAN DEFAULT FALSE,
    ai_confidence_score NUMERIC(4,3),
    was_released        BOOLEAN DEFAULT TRUE,
    regulation_compliant BOOLEAN,
    photo_url           TEXT,
    caught_at           TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -------------------------------------------------------------
-- 8. SOCIAL POSTS
-- User-generated content shared to the Reel social feed.
-- Connected to a catch or session. Powers engagement metrics.
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS social_posts (
    post_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id),
    catch_id        UUID REFERENCES catches(catch_id),
    session_id      UUID REFERENCES fishing_sessions(session_id),
    caption         TEXT,
    likes_count     INTEGER DEFAULT 0,
    comments_count  INTEGER DEFAULT 0,
    is_public       BOOLEAN DEFAULT TRUE,
    posted_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================
-- INDEXES
-- Added on foreign keys and columns used in frequent queries.
-- This is what keeps the pipeline fast at scale.
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tier ON subscriptions(tier);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON fishing_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON fishing_sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_sessions_county ON fishing_sessions(county);
CREATE INDEX IF NOT EXISTS idx_catches_session_id ON catches(session_id);
CREATE INDEX IF NOT EXISTS idx_catches_user_id ON catches(user_id);
CREATE INDEX IF NOT EXISTS idx_catches_species_id ON catches(species_id);
CREATE INDEX IF NOT EXISTS idx_gps_session_id ON gps_events(session_id);
CREATE INDEX IF NOT EXISTS idx_social_posts_user_id ON social_posts(user_id);

