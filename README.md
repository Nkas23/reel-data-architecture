# 🎣 Reel App — Data Architecture Portfolio

> **Nicolas Gonzalez** | Data Architect & Senior Data Engineer  
> Tampa, FL (Open to Remote) | [LinkedIn](https://www.linkedin.com/in/nicolas-gonzalez1/) | [Portfolio](https://nkas23.github.io)

---

## Overview

This repository demonstrates a **production-grade Medallion Architecture** 
(Bronze → Silver → Gold) built on top of the **Reel fishing app** — a 
real mobile application for iOS and Android that tracks fishing sessions, 
AI fish identification, regulation compliance, GPS tracking, and social 
features across Florida.

The data pipeline ingests raw operational data from a **Supabase/PostgreSQL** 
source database, loads it into **Snowflake** as the cloud data warehouse, 
transforms it through **dbt** models across three medallion layers, and 
delivers business KPIs through a **Power BI** dashboard.

> **Note:** The Reel app is currently in pre-launch development. All data 
> used in this portfolio is synthetically generated to mirror real production 
> behavior — a standard practice for pipeline development and architecture 
> validation before go-live.

---

## Architecture Overview

| Layer | Description |
|---|---|
| **Source** | Supabase / PostgreSQL — operational Reel app database |
| **Bronze** | Raw ingestion — exact copy of source tables via Python |
| **Silver** | Cleaned, typed, validated — dbt transformation models |
| **Gold** | Aggregated KPI-ready tables — dbt aggregation models |
| **Dashboard** | Power BI — Reel business metrics and executive KPIs |

> Data flows top to bottom: Source → Bronze → Silver → Gold → Dashboard

---

## Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Source Database | Supabase / PostgreSQL | Operational app database |
| Ingestion | Python 3.x | Extract from Supabase, load to Snowflake |
| Cloud Warehouse | Snowflake | Scalable analytics storage |
| Transformation | dbt Core | Bronze → Silver → Gold models |
| Visualization | Power BI | Executive KPI dashboard |
| Version Control | GitHub | All code, docs, and diagrams |
| Documentation | Markdown | Architecture docs and data dictionary |

---

## Repository Structure

| Folder | File | Description |
|---|---|---|
| `database/` | `schema.sql` | Full PostgreSQL schema — 8 tables |
| `docs/` | `architecture_overview.md` | Detailed architecture decisions |
| `docs/` | `data_dictionary.md` | Every table and column defined |
| `seed_data/` | `generate_seed_data.py` | Synthetic data generator — 500+ records |
| `bronze/` | `load_to_snowflake.py` | Python ingestion: Supabase → Snowflake |
| `dbt_reel/` | `dbt_project.yml` | dbt project configuration |
| `dbt_reel/` | `models/silver/` | 7 silver cleaning models |
| `dbt_reel/` | `models/gold/` | 5 gold aggregation models |
| `dashboard/` | `reel_kpi_dashboard.pbix` | Power BI dashboard file |
---

## The Reel App — Business Context

Reel is a mobile fishing app with three subscription tiers:

| Tier | Price | Key Features |
|---|---|---|
| Free | $0 | Session tracking, basic catch log |
| Standard | $4.99/month | AI fish identification, regulation checker |
| Pro | $9.99/month | Premium discovery map, advanced analytics |

The data architecture powers three core app capabilities:
- **Smart Insights** — personalized fishing analytics per user
- **Species Forecast** — ML-ready catch data by location and season  
- **Business Analytics** — conversion funnel and revenue tracking

---

## Database Schema

The operational database consists of 8 tables designed around 
the Reel app user journey:

| Table | Type | Description |
|---|---|---|
| `users` | Dimension | Every registered app account |
| `subscriptions` | Fact | All subscription events per user |
| `species` | Dimension | Fish species reference (Florida) |
| `regulations` | Dimension | FWC size, bag, and season limits |
| `fishing_sessions` | Fact | Every fishing trip logged |
| `gps_events` | Fact (high volume) | GPS pings during sessions |
| `catches` | Fact | Every fish caught and identified |
| `social_posts` | Fact | User feed posts and engagement |

📄 Full schema: [`database/schema.sql`](database/schema.sql)

---

## KPI Dashboard — Business Metrics

The Gold layer powers a Power BI dashboard tracking:

- 📈 **User Retention** — Day 7 and Day 30 cohort retention rates
- 💰 **Free → Paid Conversion** — conversion rate and average days to convert
- 💵 **Monthly Recurring Revenue** — by subscription tier
- 🐟 **Species Leaderboard** — top 10 most caught species in Florida
- 🗺️ **Regional Activity** — most active fishing counties in Florida
- ⏱️ **Session Analytics** — frequency and duration by subscription tier

---

## Data Governance

- **Primary Keys:** UUID format across all tables for global uniqueness 
  and cross-system compatibility
- **Row Level Security:** Enabled on all Supabase tables — users can 
  only access their own data
- **Indexes:** Applied to all foreign keys and high-frequency filter 
  columns for query performance
- **Computed Columns:** `duration_minutes` auto-calculated from 
  session start/end — no application logic required
- **Audit Trail:** `created_at` and `updated_at` timestamps on all 
  core tables

📄 Full data dictionary: [`docs/data_dictionary.md`](docs/data_dictionary.md)

---

## Author

**Nicolas Gonzalez**  
Senior Operations Analyst → Data Architect  
Franklin Energy Services | Tampa, FL

- 🎓 M.S. Management Sciences & Quantitative Methods  
- 🎓 B.B.A. Business Administration, Minor in Marketing  
- 🛠️ SQL · Python · R · Snowflake · dbt · Power BI · Tableau · Azure · Git

> *"I build data systems that connect raw operational events to 
> business decisions — from mobile app database to executive dashboard."*

---

*Built as a portfolio project to demonstrate end-to-end data 
architecture skills. The Reel app is a real product in development.*