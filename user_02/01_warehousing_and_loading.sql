/*=============================================================================
  Section 1: Warehousing and Data Loading
  Carnival Gaming HOL -- User 02
  
  In this section you will:
  - Set up your database schemas (RAW_GAMING, HARMONIZED, ANALYTICS)
  - Create raw tables for cruise ship gaming data
  - Load data from the shared stage
  - Explore the data with basic queries
=============================================================================*/

-- Step 1: Set your context
USE ROLE HOL_USER_02_ROLE;
USE WAREHOUSE HOL_USER_02_WH;
USE DATABASE HOL_USER_02_DB;

-- Step 2: Create schemas for the medallion architecture
CREATE SCHEMA IF NOT EXISTS RAW_GAMING;
CREATE SCHEMA IF NOT EXISTS HARMONIZED;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Step 3: Create raw tables
USE SCHEMA RAW_GAMING;

CREATE OR REPLACE TABLE SHIPS (
    ship_id INT,
    ship_name VARCHAR,
    brand VARCHAR,
    passenger_capacity INT,
    home_port VARCHAR,
    launch_year INT
);

CREATE OR REPLACE TABLE VOYAGES (
    voyage_id INT,
    ship_id INT,
    departure_date DATE,
    return_date DATE,
    itinerary_name VARCHAR,
    sea_days INT,
    port_days INT
);

CREATE OR REPLACE TABLE CASINO_GAMES (
    game_id INT,
    game_type VARCHAR,
    game_name VARCHAR,
    min_bet FLOAT,
    max_bet FLOAT,
    location_deck VARCHAR
);

CREATE OR REPLACE TABLE PLAYERS (
    player_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    loyalty_tier VARCHAR,
    home_city VARCHAR,
    home_state VARCHAR,
    membership_date DATE
);

CREATE OR REPLACE TABLE GAMING_TRANSACTIONS (
    txn_id INT,
    player_id INT,
    game_id INT,
    ship_id INT,
    voyage_id INT,
    txn_timestamp TIMESTAMP,
    bet_amount FLOAT,
    payout_amount FLOAT,
    net_revenue FLOAT
);

CREATE OR REPLACE TABLE PLAYER_REVIEWS (
    review_id INT,
    player_id INT,
    ship_id INT,
    voyage_id INT,
    review_text VARCHAR,
    rating INT,
    review_date DATE,
    language VARCHAR
);

-- Step 4: Load data from the shared stage
COPY INTO SHIPS FROM @HOL_SHARED.PUBLIC.GAMING_DATA/ships.csv
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO VOYAGES FROM @HOL_SHARED.PUBLIC.GAMING_DATA/voyages.csv
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO CASINO_GAMES FROM @HOL_SHARED.PUBLIC.GAMING_DATA/casino_games.csv
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO PLAYERS FROM @HOL_SHARED.PUBLIC.GAMING_DATA/players.csv
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO GAMING_TRANSACTIONS FROM @HOL_SHARED.PUBLIC.GAMING_DATA/gaming_transactions.csv
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO PLAYER_REVIEWS FROM @HOL_SHARED.PUBLIC.GAMING_DATA/player_reviews.csv
  FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- Step 5: Verify the data loaded correctly
SELECT 'SHIPS' AS table_name, COUNT(*) AS row_count FROM SHIPS
UNION ALL SELECT 'VOYAGES', COUNT(*) FROM VOYAGES
UNION ALL SELECT 'CASINO_GAMES', COUNT(*) FROM CASINO_GAMES
UNION ALL SELECT 'PLAYERS', COUNT(*) FROM PLAYERS
UNION ALL SELECT 'GAMING_TRANSACTIONS', COUNT(*) FROM GAMING_TRANSACTIONS
UNION ALL SELECT 'PLAYER_REVIEWS', COUNT(*) FROM PLAYER_REVIEWS;

-- Step 6: Explore the data

-- What ships are in our fleet?
SELECT ship_name, brand, passenger_capacity, home_port
FROM SHIPS
ORDER BY brand, ship_name;

-- What are the top revenue-generating game types?
SELECT g.game_type,
       COUNT(*) AS total_transactions,
       ROUND(SUM(t.bet_amount), 2) AS total_wagered,
       ROUND(SUM(t.net_revenue), 2) AS total_revenue
FROM GAMING_TRANSACTIONS t
JOIN CASINO_GAMES g ON t.game_id = g.game_id
GROUP BY g.game_type
ORDER BY total_revenue DESC;

-- Revenue by brand (Carnival vs Holland America)
SELECT s.brand,
       COUNT(*) AS total_transactions,
       ROUND(SUM(t.bet_amount), 2) AS total_wagered,
       ROUND(SUM(t.net_revenue), 2) AS total_revenue,
       ROUND(AVG(t.bet_amount), 2) AS avg_bet_size
FROM GAMING_TRANSACTIONS t
JOIN SHIPS s ON t.ship_id = s.ship_id
GROUP BY s.brand
ORDER BY total_revenue DESC;
