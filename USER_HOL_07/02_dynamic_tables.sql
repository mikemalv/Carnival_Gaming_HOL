/*=============================================================================
  Section 2: Automated Pipelines with Dynamic Tables
  Carnival Gaming HOL -- User 07
  
  In this section you will:
  - Create Dynamic Tables that automatically transform raw gaming data
  - Build a multi-layer pipeline: RAW -> HARMONIZED -> ANALYTICS
  - Observe how downstream tables refresh when upstream data changes
=============================================================================*/

USE ROLE HOL_USER_07_ROLE;
USE WAREHOUSE HOL_USER_07_WH;
USE DATABASE HOL_USER_07_DB;

-- ==========================================================================
-- HARMONIZED LAYER: Join and enrich raw data
-- ==========================================================================

-- Dynamic Table 1: Enriched gaming transactions
-- Joins transactions with ship, game, and player details
CREATE OR REPLACE DYNAMIC TABLE HARMONIZED.GAMING_TRANSACTIONS_H
  TARGET_LAG = '1 minute'
  WAREHOUSE = HOL_USER_07_WH
AS
SELECT
    t.txn_id,
    t.txn_timestamp,
    t.bet_amount,
    t.payout_amount,
    t.net_revenue,
    -- Player info
    t.player_id,
    p.first_name || ' ' || p.last_name AS player_name,
    p.loyalty_tier,
    -- Ship info
    s.ship_id,
    s.ship_name,
    s.brand,
    -- Game info
    g.game_id,
    g.game_type,
    g.game_name,
    -- Voyage info
    v.voyage_id,
    v.itinerary_name,
    v.sea_days,
    v.port_days,
    v.departure_date,
    v.return_date,
    -- Derived: was this transaction on a sea day or port day?
    CASE
        WHEN DAYOFWEEK(t.txn_timestamp) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    -- Derived: profit/loss from player perspective
    t.payout_amount - t.bet_amount AS player_profit_loss
FROM RAW_GAMING.GAMING_TRANSACTIONS t
JOIN RAW_GAMING.PLAYERS p ON t.player_id = p.player_id
JOIN RAW_GAMING.SHIPS s ON t.ship_id = s.ship_id
JOIN RAW_GAMING.CASINO_GAMES g ON t.game_id = g.game_id
JOIN RAW_GAMING.VOYAGES v ON t.voyage_id = v.voyage_id;

-- Dynamic Table 2: Player summary roll-up
CREATE OR REPLACE DYNAMIC TABLE HARMONIZED.PLAYER_SUMMARY_H
  TARGET_LAG = '1 minute'
  WAREHOUSE = HOL_USER_07_WH
AS
SELECT
    p.player_id,
    p.first_name || ' ' || p.last_name AS player_name,
    p.loyalty_tier,
    p.home_city,
    p.home_state,
    COUNT(DISTINCT t.voyage_id) AS voyages_played,
    COUNT(*) AS total_bets,
    ROUND(SUM(t.bet_amount), 2) AS total_wagered,
    ROUND(SUM(t.payout_amount), 2) AS total_won,
    ROUND(SUM(t.net_revenue), 2) AS total_lost_to_house,
    ROUND(AVG(t.bet_amount), 2) AS avg_bet_size,
    MAX(t.bet_amount) AS largest_bet,
    MODE(g.game_type) AS favorite_game_type
FROM RAW_GAMING.GAMING_TRANSACTIONS t
JOIN RAW_GAMING.PLAYERS p ON t.player_id = p.player_id
JOIN RAW_GAMING.CASINO_GAMES g ON t.game_id = g.game_id
GROUP BY p.player_id, p.first_name, p.last_name, p.loyalty_tier, p.home_city, p.home_state;

-- ==========================================================================
-- ANALYTICS LAYER: Business-ready aggregations
-- ==========================================================================

-- Dynamic Table 3: Daily ship revenue dashboard
CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DAILY_SHIP_REVENUE
  TARGET_LAG = '1 minute'
  WAREHOUSE = HOL_USER_07_WH
AS
SELECT
    DATE(txn_timestamp) AS gaming_date,
    ship_name,
    brand,
    game_type,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT player_id) AS unique_players,
    ROUND(SUM(bet_amount), 2) AS total_wagered,
    ROUND(SUM(payout_amount), 2) AS total_payouts,
    ROUND(SUM(net_revenue), 2) AS house_revenue,
    ROUND(AVG(bet_amount), 2) AS avg_bet_size,
    ROUND(SUM(net_revenue) / NULLIF(SUM(bet_amount), 0) * 100, 2) AS house_edge_pct
FROM HARMONIZED.GAMING_TRANSACTIONS_H
GROUP BY DATE(txn_timestamp), ship_name, brand, game_type;

-- Dynamic Table 4: Voyage performance summary
CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.VOYAGE_PERFORMANCE
  TARGET_LAG = '1 minute'
  WAREHOUSE = HOL_USER_07_WH
AS
SELECT
    v.voyage_id,
    s.ship_name,
    s.brand,
    v.itinerary_name,
    v.departure_date,
    v.return_date,
    v.sea_days,
    v.port_days,
    v.sea_days + v.port_days AS total_days,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT t.player_id) AS unique_players,
    ROUND(SUM(t.bet_amount), 2) AS total_wagered,
    ROUND(SUM(t.net_revenue), 2) AS house_revenue,
    ROUND(SUM(t.net_revenue) / NULLIF(v.sea_days + v.port_days, 0), 2) AS revenue_per_day,
    ROUND(SUM(t.net_revenue) / NULLIF(s.passenger_capacity, 0), 2) AS revenue_per_passenger
FROM RAW_GAMING.GAMING_TRANSACTIONS t
JOIN RAW_GAMING.SHIPS s ON t.ship_id = s.ship_id
JOIN RAW_GAMING.VOYAGES v ON t.voyage_id = v.voyage_id
GROUP BY v.voyage_id, s.ship_name, s.brand, v.itinerary_name,
         v.departure_date, v.return_date, v.sea_days, v.port_days, s.passenger_capacity;

-- ==========================================================================
-- Verify: Check Dynamic Table status
-- ==========================================================================

-- See all your Dynamic Tables and their refresh status
SHOW DYNAMIC TABLES IN DATABASE HOL_USER_07_DB;

-- Query the analytics layer
SELECT ship_name, brand, game_type,
       SUM(house_revenue) AS total_revenue,
       ROUND(AVG(house_edge_pct), 2) AS avg_house_edge
FROM ANALYTICS.DAILY_SHIP_REVENUE
GROUP BY ship_name, brand, game_type
ORDER BY total_revenue DESC
LIMIT 20;

-- Top voyages by revenue per passenger
SELECT ship_name, brand, itinerary_name, departure_date,
       total_wagered, house_revenue, revenue_per_passenger, unique_players
FROM ANALYTICS.VOYAGE_PERFORMANCE
ORDER BY revenue_per_passenger DESC
LIMIT 10;
