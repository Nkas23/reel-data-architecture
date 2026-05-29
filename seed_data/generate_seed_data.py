 # =============================================================
# Reel App — Synthetic Data Generator
# Author: Nicolas Gonzalez
# Description: Generates realistic synthetic data for the Reel
#              fishing app database. Produces a SQL file ready
#              to load into Supabase for pipeline development
#              and portfolio demonstration.
# =============================================================

import random
import uuid
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()
random.seed(42)

# =============================================================
# REFERENCE DATA — Florida-specific realistic values
# =============================================================

FLORIDA_COUNTIES = [
    "Miami-Dade", "Broward", "Palm Beach", "Hillsborough",
    "Pinellas", "Orange", "Duval", "Lee", "Collier", "Sarasota",
    "Manatee", "Brevard", "Volusia", "Escambia", "Leon"
]

FLORIDA_CITIES = [
    "Tampa", "Miami", "Orlando", "Jacksonville", "St. Petersburg",
    "Fort Lauderdale", "Clearwater", "Sarasota", "Naples", "Key West",
    "Gainesville", "Tallahassee", "Pensacola", "Daytona Beach", "Fort Myers"
]

WATER_BODY_TYPES = ["lake", "river", "ocean", "bay", "pond", "canal"]

WEATHER_CONDITIONS = ["sunny", "cloudy", "rainy", "windy", "partly cloudy"]

SUBSCRIPTION_TIERS = [
    {"tier": "free",     "price": 0.00},
    {"tier": "standard", "price": 4.99},
    {"tier": "pro",      "price": 9.99},
]

FLORIDA_SPECIES = [
    ("Largemouth Bass",    "Micropterus salmoides",      "freshwater"),
    ("Smallmouth Bass",    "Micropterus dolomieu",       "freshwater"),
    ("Bluegill",           "Lepomis macrochirus",        "freshwater"),
    ("Channel Catfish",    "Ictalurus punctatus",        "freshwater"),
    ("Black Crappie",      "Pomoxis nigromaculatus",     "freshwater"),
    ("Redfish",            "Sciaenops ocellatus",        "saltwater"),
    ("Snook",              "Centropomus undecimalis",    "saltwater"),
    ("Tarpon",             "Megalops atlanticus",        "saltwater"),
    ("Red Snapper",        "Lutjanus campechanus",       "saltwater"),
    ("Flounder",           "Paralichthys lethostigma",   "saltwater"),
    ("Spotted Seatrout",   "Cynoscion nebulosus",        "saltwater"),
    ("King Mackerel",      "Scomberomorus cavalla",      "saltwater"),
    ("Striped Bass",       "Morone saxatilis",           "both"),
    ("Cobia",              "Rachycentron canadum",       "saltwater"),
    ("Mahi-Mahi",          "Coryphaena hippurus",        "saltwater"),
]

# GPS bounding box for Florida waters
FL_LAT_MIN, FL_LAT_MAX = 24.5, 31.0
FL_LON_MIN, FL_LON_MAX = -87.6, -80.0

# =============================================================
# HELPER FUNCTIONS
# =============================================================

def new_id():
    """Generate a new UUID string."""
    return str(uuid.uuid4())

def rand_fl_lat():
    """Random latitude inside Florida."""
    return round(random.uniform(FL_LAT_MIN, FL_LAT_MAX), 6)

def rand_fl_lon():
    """Random longitude inside Florida."""
    return round(random.uniform(FL_LON_MIN, FL_LON_MAX), 6)

def rand_date(start_days_ago=365, end_days_ago=0):
    """Random datetime between start and end days ago."""
    start = datetime.now() - timedelta(days=start_days_ago)
    end   = datetime.now() - timedelta(days=end_days_ago)
    delta = end - start
    return start + timedelta(seconds=random.randint(0, int(delta.total_seconds())))

def sql_dt(dt):
    """Format datetime for SQL insertion."""
    return dt.strftime("%Y-%m-%d %H:%M:%S+00")

def sql_date(dt):
    """Format date only for SQL insertion."""
    return dt.strftime("%Y-%m-%d")

def escape(text):
    """Escape single quotes for SQL strings."""
    return text.replace("'", "''")

# =============================================================
# GENERATOR FUNCTIONS — one per table
# =============================================================

def generate_species():
    """Generate the 15 Florida species reference rows."""
    lines = []
    species_ids = []
    lines.append("-- SPECIES")
    lines.append("INSERT INTO species (species_id, common_name, scientific_name, habitat, native_to_fl, created_at) VALUES")
    rows = []
    for common, scientific, habitat in FLORIDA_SPECIES:
        sid = new_id()
        species_ids.append({"id": sid, "name": common, "habitat": habitat})
        rows.append(
            f"  ('{sid}', '{common}', '{scientific}', '{habitat}', TRUE, '{sql_dt(rand_date(730, 365))}')"
        )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines), species_ids


def generate_regulations(species_ids):
    """Generate one regulation record per species."""
    lines = []
    lines.append("\n-- REGULATIONS")
    lines.append("INSERT INTO regulations (regulation_id, species_id, region, min_size_inches, bag_limit, season_open, season_close, effective_date, created_at) VALUES")
    rows = []
    size_map = {
        "Largemouth Bass": (14.0, 5), "Smallmouth Bass": (12.0, 5),
        "Bluegill": (None, 50),       "Channel Catfish": (12.0, 20),
        "Black Crappie": (10.0, 25),  "Redfish": (18.0, 1),
        "Snook": (28.0, 1),           "Tarpon": (None, 0),
        "Red Snapper": (16.0, 2),     "Flounder": (12.0, 10),
        "Spotted Seatrout": (15.0, 3),"King Mackerel": (24.0, 2),
        "Striped Bass": (18.0, 3),    "Cobia": (33.0, 1),
        "Mahi-Mahi": (20.0, 10),
    }
    for sp in species_ids:
        rid = new_id()
        size, bag = size_map.get(sp["name"], (12.0, 5))
        size_val = f"{size}" if size else "NULL"
        bag_val  = str(bag)
        rows.append(
            f"  ('{rid}', '{sp['id']}', 'Statewide', {size_val}, {bag_val}, NULL, NULL, '2024-01-01', '{sql_dt(rand_date(730, 365))}')"
        )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines)


def generate_users(n=100):
    """Generate n realistic Florida users."""
    lines = []
    user_ids = []
    lines.append("\n-- USERS")
    lines.append("INSERT INTO users (user_id, email, display_name, state, city, created_at, updated_at) VALUES")
    rows = []
    for _ in range(n):
        uid        = new_id()
        created    = rand_date(365, 0)
        city       = random.choice(FLORIDA_CITIES)
        name       = fake.user_name()
        email      = fake.unique.email()
        user_ids.append({"id": uid, "created_at": created})
        rows.append(
            f"  ('{uid}', '{escape(email)}', '{escape(name)}', 'Florida', '{city}', '{sql_dt(created)}', '{sql_dt(created)}')"
        )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines), user_ids


def generate_subscriptions(user_ids):
    """Generate subscription history for each user.
    
    Logic mirrors real app behavior:
    - All users start on free tier
    - 40% convert to standard or pro
    - Some users upgrade from standard to pro over time
    """
    lines = []
    lines.append("\n-- SUBSCRIPTIONS")
    lines.append("INSERT INTO subscriptions (subscription_id, user_id, tier, price_usd, status, started_at, ended_at, created_at) VALUES")
    rows = []
    for user in user_ids:
        signup = user["created_at"]

        # Every user starts free
        rows.append(
            f"  ('{new_id()}', '{user['id']}', 'free', 0.00, 'active', '{sql_dt(signup)}', NULL, '{sql_dt(signup)}')"
        )

        # 40% of users convert to paid
        if random.random() < 0.40:
            days_to_convert = random.randint(1, 60)
            convert_date    = signup + timedelta(days=days_to_convert)
            tier            = random.choice(["standard", "pro"])
            price           = 4.99 if tier == "standard" else 9.99

            # Close the free subscription
            rows.append(
                f"  ('{new_id()}', '{user['id']}', 'free', 0.00, 'expired', '{sql_dt(signup)}', '{sql_dt(convert_date)}', '{sql_dt(signup)}')"
            )
            # Open the paid subscription
            rows.append(
                f"  ('{new_id()}', '{user['id']}', '{tier}', {price}, 'active', '{sql_dt(convert_date)}', NULL, '{sql_dt(convert_date)}')"
            )

    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines)


def generate_sessions(user_ids, n_sessions=300):
    """Generate fishing sessions across Florida."""
    lines = []
    session_ids = []
    lines.append("\n-- FISHING SESSIONS")
    lines.append("INSERT INTO fishing_sessions (session_id, user_id, started_at, ended_at, location_name, water_body_type, county, weather, notes, created_at) VALUES")
    rows = []
    for _ in range(n_sessions):
        sid        = new_id()
        user       = random.choice(user_ids)
        start      = rand_date(365, 0)
        duration   = random.randint(30, 480)
        end        = start + timedelta(minutes=duration)
        county     = random.choice(FLORIDA_COUNTIES)
        water_type = random.choice(WATER_BODY_TYPES)
        weather    = random.choice(WEATHER_CONDITIONS)
        location   = f"{county} {water_type.title()}"
        session_ids.append({"id": sid, "user_id": user["id"], "started_at": start})
        rows.append(
            f"  ('{sid}', '{user['id']}', '{sql_dt(start)}', '{sql_dt(end)}', '{location}', '{water_type}', '{county}', '{weather}', NULL, '{sql_dt(start)}')"
        )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines), session_ids


def generate_catches(session_ids, species_ids, n_catches=500):
    """Generate catch records linked to sessions and species."""
    lines = []
    lines.append("\n-- CATCHES")
    lines.append("INSERT INTO catches (catch_id, session_id, user_id, species_id, length_inches, weight_lbs, ai_identified, ai_confidence_score, was_released, regulation_compliant, caught_at, created_at) VALUES")
    rows = []
    for _ in range(n_catches):
        session     = random.choice(session_ids)
        species     = random.choice(species_ids)
        caught_at   = session["started_at"] + timedelta(minutes=random.randint(10, 240))
        length      = round(random.uniform(6.0, 36.0), 2)
        weight      = round(random.uniform(0.5, 15.0), 2)
        ai_used     = random.random() < 0.70
        confidence  = round(random.uniform(0.65, 0.99), 3) if ai_used else "NULL"
        released    = random.random() < 0.60
        compliant   = random.random() < 0.85
        rows.append(
            f"  ('{new_id()}', '{session['id']}', '{session['user_id']}', '{species['id']}', {length}, {weight}, {'TRUE' if ai_used else 'FALSE'}, {confidence}, {'TRUE' if released else 'FALSE'}, {'TRUE' if compliant else 'FALSE'}, '{sql_dt(caught_at)}', '{sql_dt(caught_at)}')"
        )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines)


def generate_gps_events(session_ids, n_per_session=5):
    """Generate GPS ping events for each session."""
    lines = []
    lines.append("\n-- GPS EVENTS")
    lines.append("INSERT INTO gps_events (gps_id, session_id, user_id, latitude, longitude, recorded_at, accuracy_meters, created_at) VALUES")
    rows = []
    for session in session_ids:
        for i in range(n_per_session):
            ping_time = session["started_at"] + timedelta(minutes=i * 15)
            rows.append(
                f"  ('{new_id()}', '{session['id']}', '{session['user_id']}', {rand_fl_lat()}, {rand_fl_lon()}, '{sql_dt(ping_time)}', {round(random.uniform(3.0, 15.0), 2)}, '{sql_dt(ping_time)}')"
            )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines)


def generate_social_posts(session_ids, n_posts=150):
    """Generate social feed posts linked to sessions."""
    lines = []
    lines.append("\n-- SOCIAL POSTS")
    lines.append("INSERT INTO social_posts (post_id, user_id, session_id, caption, likes_count, comments_count, is_public, posted_at, created_at) VALUES")
    rows = []
    captions = [
        "Great day on the water!",
        "Nothing beats a Florida sunrise fishing trip.",
        "Caught and released — beauty of a fish.",
        "Early morning session paid off today.",
        "The one that almost got away.",
        "Perfect conditions out there today.",
        "Another successful trip in the books.",
        "Florida fishing never disappoints.",
    ]
    for _ in range(n_posts):
        session  = random.choice(session_ids)
        posted   = session["started_at"] + timedelta(hours=random.randint(1, 5))
        caption  = random.choice(captions)
        likes    = random.randint(0, 120)
        comments = random.randint(0, 30)
        rows.append(
            f"  ('{new_id()}', '{session['user_id']}', '{session['id']}', '{escape(caption)}', {likes}, {comments}, TRUE, '{sql_dt(posted)}', '{sql_dt(posted)}')"
        )
    lines.append(",\n".join(rows) + ";")
    return "\n".join(lines)


# =============================================================
# MAIN — orchestrate all generators and write output file
# =============================================================

def main():
    print("Reel App — Synthetic Data Generator")
    print("Author: Nicolas Gonzalez")
    print("=" * 50)

    output_lines = []
    output_lines.append("-- =============================================================")
    output_lines.append("-- Reel App — Synthetic Seed Data")
    output_lines.append("-- Author: Nicolas Gonzalez")
    output_lines.append("-- Generated by: seed_data/generate_seed_data.py")
    output_lines.append("-- Description: Realistic synthetic data for portfolio")
    output_lines.append("--              demonstration. Mirrors expected production")
    output_lines.append("--              behavior of the live Reel fishing app.")
    output_lines.append("-- =============================================================")
    output_lines.append("")

    print("Generating species...")
    species_sql, species_ids = generate_species()
    output_lines.append(species_sql)

    print("Generating regulations...")
    output_lines.append(generate_regulations(species_ids))

    print("Generating 100 users...")
    users_sql, user_ids = generate_users(100)
    output_lines.append(users_sql)

    print("Generating subscriptions...")
    output_lines.append(generate_subscriptions(user_ids))

    print("Generating 300 fishing sessions...")
    sessions_sql, session_ids = generate_sessions(user_ids, 300)
    output_lines.append(sessions_sql)

    print("Generating 500 catches...")
    output_lines.append(generate_catches(session_ids, species_ids, 500))

    print("Generating GPS events...")
    output_lines.append(generate_gps_events(session_ids))

    print("Generating 150 social posts...")
    output_lines.append(generate_social_posts(session_ids, 150))

    output_path = "seed_data/seed_data.sql"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(output_lines))

    print("=" * 50)
    print(f"Done! Output written to: {output_path}")
    print(f"  Species:      {len(species_ids)}")
    print(f"  Users:        100")
    print(f"  Sessions:     300")
    print(f"  Catches:      500")
    print(f"  GPS events:   {300 * 5}")
    print(f"  Social posts: 150")
    print("=" * 50)
    print("Next step: load seed_data/seed_data.sql into Supabase SQL Editor")


if __name__ == "__main__":
    main()
