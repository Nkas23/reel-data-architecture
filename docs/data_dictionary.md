 # Reel App — Data Dictionary

> **Author:** Nicolas Gonzalez  
> **Last Updated:** 2026
> **Database:** Supabase / PostgreSQL  
> **Purpose:** Complete reference for every table and column in the 
> Reel app operational database. Used as the foundation for the 
> Medallion architecture pipeline (Bronze → Silver → Gold).

---

## Table Index

| Table | Type | Row Volume | Description |
|---|---|---|---|
| `users` | Dimension | Low | Every registered app account |
| `subscriptions` | Fact | Low | All subscription events per user |
| `species` | Dimension | Static | Fish species reference for Florida |
| `regulations` | Dimension | Static | FWC size, bag, and season limits |
| `fishing_sessions` | Fact | Medium | Every fishing trip logged in the app |
| `gps_events` | Fact | High | GPS coordinate pings during sessions |
| `catches` | Fact | Medium | Every fish caught and identified |
| `social_posts` | Fact | Medium | User feed posts and engagement |

---

## users

**Purpose:** Root table for the entire database. Every other fact table 
connects back to a user. Stores account information and location data 
used for regional analytics.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `user_id` | UUID | PK, NOT NULL | Unique identifier — auto-generated on signup |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | Login email address |
| `display_name` | VARCHAR(100) | NOT NULL | Public username shown in the app |
| `state` | VARCHAR(50) | nullable | US state — defaults to Florida for most users |
| `city` | VARCHAR(100) | nullable | City used for regional leaderboards |
| `created_at` | TIMESTAMPTZ | NOT NULL | Account creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL | Last profile update timestamp |

**Business Notes:**
- `created_at` is used as the cohort date for retention analysis
- `city` and `state` power the regional activity heatmap in the Gold layer
- Used by: subscriptions, fishing_sessions, catches, gps_events, social_posts

---

## subscriptions

**Purpose:** Tracks every subscription state change per user — 
signups, upgrades, downgrades, and cancellations. One user can have 
multiple rows over time. This is the source of truth for revenue 
and conversion funnel metrics.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `subscription_id` | UUID | PK, NOT NULL | Unique identifier per subscription event |
| `user_id` | UUID | FK → users, NOT NULL | The user this subscription belongs to |
| `tier` | VARCHAR(20) | NOT NULL | free / standard / pro |
| `price_usd` | NUMERIC(6,2) | NOT NULL | 0.00 / 4.99 / 9.99 |
| `status` | VARCHAR(20) | NOT NULL | active / cancelled / expired |
| `started_at` | TIMESTAMPTZ | NOT NULL | When this subscription period began |
| `ended_at` | TIMESTAMPTZ | nullable | When it ended — NULL means currently active |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- To find a user's current tier: filter where `status = active` and `ended_at IS NULL`
- Days between first `free` row and first `standard` or `pro` row = days to convert
- Monthly Recurring Revenue = SUM of `price_usd` where `status = active`

---

## species

**Purpose:** Master reference table for all fish species supported 
in the Reel app. Used by the AI identification feature and the 
regulation compliance checker. Data rarely changes.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `species_id` | UUID | PK, NOT NULL | Unique identifier per species |
| `common_name` | VARCHAR(100) | NOT NULL | e.g. Largemouth Bass, Red Snapper |
| `scientific_name` | VARCHAR(150) | nullable | e.g. Micropterus salmoides |
| `habitat` | VARCHAR(50) | nullable | freshwater / saltwater / both |
| `native_to_fl` | BOOLEAN | DEFAULT TRUE | Whether native to Florida waters |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- Used in the species leaderboard Gold model
- Connected to regulations for compliance checking
- AI identification results write `species_id` to the catches table

---

## regulations

**Purpose:** Florida Fish and Wildlife Conservation Commission (FWC) 
regulations per species. Powers the real-time compliance check 
feature — one of Reel's core Standard and Pro tier features.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `regulation_id` | UUID | PK, NOT NULL | Unique identifier per regulation record |
| `species_id` | UUID | FK → species, NOT NULL | The species this regulation applies to |
| `region` | VARCHAR(100) | NOT NULL | e.g. Statewide, South Florida, Gulf Coast |
| `min_size_inches` | NUMERIC(5,2) | nullable | Minimum legal size to keep |
| `bag_limit` | INTEGER | nullable | Maximum fish per person per day |
| `season_open` | DATE | nullable | Start of open season — NULL means year-round |
| `season_close` | DATE | nullable | End of open season — NULL means year-round |
| `notes` | TEXT | nullable | Additional FWC regulation notes |
| `effective_date` | DATE | NOT NULL | Date this regulation became active |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- NULL season_open and season_close means the species is open year-round
- Compliance check compares catch `length_inches` against `min_size_inches`
- Regulation updates trigger a new row — old rows are kept for audit history

---

## fishing_sessions

**Purpose:** The central fact table. Every time a user starts a 
fishing trip in the app a session is created. Catches and GPS events 
both belong to a session. Session data powers time-based analytics 
and regional activity maps.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `session_id` | UUID | PK, NOT NULL | Unique identifier per fishing trip |
| `user_id` | UUID | FK → users, NOT NULL | The user who started this session |
| `started_at` | TIMESTAMPTZ | NOT NULL | Trip start time |
| `ended_at` | TIMESTAMPTZ | nullable | Trip end time — NULL if session still active |
| `duration_minutes` | INTEGER | COMPUTED | Auto-calculated from started_at and ended_at |
| `location_name` | VARCHAR(200) | nullable | User-entered location name |
| `water_body_type` | VARCHAR(50) | nullable | lake / river / ocean / bay / pond / canal |
| `county` | VARCHAR(100) | nullable | Florida county — used for regional heatmaps |
| `weather` | VARCHAR(50) | nullable | sunny / cloudy / rainy / windy |
| `notes` | TEXT | nullable | User notes about the trip |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- `duration_minutes` is a PostgreSQL computed column — never write to it directly
- `county` is the key field for the regional activity Gold model
- Sessions with no `ended_at` are considered in-progress and excluded from analytics

---

## gps_events

**Purpose:** Individual GPS coordinate pings recorded during an 
active session. High volume table — a 3-hour session can generate 
hundreds of rows. Powers the map trail feature and regional 
density heatmaps in the Pro tier discovery map.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `gps_id` | UUID | PK, NOT NULL | Unique identifier per GPS ping |
| `session_id` | UUID | FK → fishing_sessions, NOT NULL | The session this ping belongs to |
| `user_id` | UUID | FK → users, NOT NULL | Denormalized for query performance |
| `latitude` | NUMERIC(9,6) | NOT NULL | GPS latitude — 6 decimal places = ~10cm accuracy |
| `longitude` | NUMERIC(9,6) | NOT NULL | GPS longitude |
| `recorded_at` | TIMESTAMPTZ | NOT NULL | Exact timestamp of this ping |
| `accuracy_meters` | NUMERIC(6,2) | nullable | GPS accuracy radius from the device |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- `user_id` is intentionally denormalized here for faster regional queries
- NUMERIC(9,6) provides ~0.1 meter precision — sufficient for fishing location analysis
- This is the highest volume table in the database — partition by month at scale

---

## catches

**Purpose:** Every fish logged during a session. The core product 
table — this is what the Reel app is built around. Connects to 
species for identification, regulations for compliance, and social 
posts for sharing. Powers the species leaderboard and AI accuracy metrics.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `catch_id` | UUID | PK, NOT NULL | Unique identifier per catch |
| `session_id` | UUID | FK → fishing_sessions, NOT NULL | The session this catch belongs to |
| `user_id` | UUID | FK → users, NOT NULL | Denormalized for query performance |
| `species_id` | UUID | FK → species, nullable | NULL if species could not be identified |
| `length_inches` | NUMERIC(5,2) | nullable | Measured length of the fish |
| `weight_lbs` | NUMERIC(5,2) | nullable | Measured weight of the fish |
| `ai_identified` | BOOLEAN | DEFAULT FALSE | Whether AI was used for identification |
| `ai_confidence_score` | NUMERIC(4,3) | nullable | AI confidence 0.000 to 1.000 |
| `was_released` | BOOLEAN | DEFAULT TRUE | Whether fish was released (catch and release) |
| `regulation_compliant` | BOOLEAN | nullable | Whether catch met FWC size requirements |
| `photo_url` | TEXT | nullable | URL to catch photo in storage |
| `caught_at` | TIMESTAMPTZ | NOT NULL | Exact time the fish was caught |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- `ai_confidence_score` range: 0.000 (no confidence) to 1.000 (certain)
- `regulation_compliant` is computed at catch time by comparing length to regulations
- NULL `species_id` means the AI could not identify the fish — tracked as unidentified catches

---

## social_posts

**Purpose:** User-generated content shared to the Reel social feed. 
A post can reference a specific catch, a full session, or neither. 
Powers engagement metrics and social feature analytics.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `post_id` | UUID | PK, NOT NULL | Unique identifier per post |
| `user_id` | UUID | FK → users, NOT NULL | The user who created this post |
| `catch_id` | UUID | FK → catches, nullable | The catch being shared — optional |
| `session_id` | UUID | FK → fishing_sessions, nullable | The session being shared — optional |
| `caption` | TEXT | nullable | User-written post caption |
| `likes_count` | INTEGER | DEFAULT 0 | Total likes on this post |
| `comments_count` | INTEGER | DEFAULT 0 | Total comments on this post |
| `is_public` | BOOLEAN | DEFAULT TRUE | Whether visible to all users or friends only |
| `posted_at` | TIMESTAMPTZ | NOT NULL | When the post was published |
| `created_at` | TIMESTAMPTZ | NOT NULL | Record creation timestamp |

**Business Notes:**
- Both `catch_id` and `session_id` are optional — a user can post without linking either
- `likes_count` and `comments_count` are denormalized counters for read performance
- `is_public = FALSE` posts are excluded from all analytics aggregations

---

## Naming Conventions

| Convention | Example | Reason |
|---|---|---|
| Snake case for all names | `fishing_sessions` | PostgreSQL standard |
| UUID primary keys | `user_id UUID` | Cross-system compatibility |
| `_id` suffix for all keys | `user_id`, `session_id` | Instantly recognizable in joins |
| `_at` suffix for timestamps | `created_at`, `started_at` | Distinguishes from date columns |
| `_count` suffix for counters | `likes_count` | Self-documenting |
| `is_` prefix for booleans | `is_public`, `ai_identified` | Reads as a question — true or false |

---

*This data dictionary is a living document and will be updated 
as the Reel app schema evolves toward production.*
