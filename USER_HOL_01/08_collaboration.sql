/*=============================================================================
  Section 8: Data Collaboration via Marketplace
  Carnival Gaming HOL -- User 01
  
  In this section you will:
  - Access a free dataset from the Snowflake Marketplace
  - Join external data with your gaming data
  - Analyze how weather and port days affect casino revenue
  
  NOTE: Marketplace access requires your instructor to have enabled a
  shared dataset. If Marketplace is not available, use the simulated
  weather data created in Step 1b below.
=============================================================================*/

USE ROLE HOL_USER_01_ROLE;
USE WAREHOUSE HOL_USER_01_WH;
USE DATABASE HOL_USER_01_DB;

-- ==========================================================================
-- Step 1a: Access Marketplace Data (if available)
--
-- INSTRUCTIONS:
-- 1. In Snowsight, go to Data Products > Marketplace
-- 2. Search for "Weather Source" or a free weather dataset
-- 3. Click "Get" to add it to your account
-- 4. The instructor may have already set this up for you
-- ==========================================================================

-- If a weather dataset is available, you can join it with voyage data.
-- The specific table/column names depend on which listing was installed.

-- ==========================================================================
-- Step 1b: Simulated Collaboration Data
-- If Marketplace is not available, we create sample port/weather data
-- to demonstrate the concept of data enrichment
-- ==========================================================================

CREATE SCHEMA IF NOT EXISTS COLLABORATION;

CREATE OR REPLACE TABLE COLLABORATION.PORT_WEATHER AS
SELECT 
    column1 AS port_name,
    column2 AS month_num,
    column3 AS avg_temp_f,
    column4 AS avg_precipitation_inches,
    column5 AS avg_sea_state
FROM VALUES
    ('Miami', 10, 82, 6.5, 'Calm'),
    ('Miami', 11, 77, 2.5, 'Calm'),
    ('Miami', 12, 73, 2.0, 'Calm'),
    ('Miami', 1, 71, 2.1, 'Moderate'),
    ('Port Canaveral', 10, 80, 5.8, 'Calm'),
    ('Port Canaveral', 11, 74, 2.2, 'Calm'),
    ('Port Canaveral', 12, 69, 2.5, 'Moderate'),
    ('Port Canaveral', 1, 66, 2.8, 'Moderate'),
    ('Fort Lauderdale', 10, 83, 6.2, 'Calm'),
    ('Fort Lauderdale', 11, 79, 2.8, 'Calm'),
    ('Fort Lauderdale', 12, 74, 2.1, 'Calm'),
    ('Fort Lauderdale', 1, 72, 2.5, 'Moderate'),
    ('Galveston', 10, 78, 4.5, 'Moderate'),
    ('Galveston', 11, 65, 3.8, 'Moderate'),
    ('Galveston', 12, 57, 3.5, 'Rough'),
    ('Galveston', 1, 54, 4.2, 'Rough'),
    ('New York', 10, 60, 3.8, 'Moderate'),
    ('New York', 11, 48, 3.5, 'Rough'),
    ('New York', 12, 38, 3.2, 'Rough'),
    ('New York', 1, 34, 3.5, 'Rough'),
    ('Long Beach', 10, 72, 0.5, 'Calm'),
    ('Long Beach', 11, 65, 1.2, 'Calm'),
    ('Long Beach', 12, 60, 2.5, 'Moderate'),
    ('Long Beach', 1, 58, 3.2, 'Moderate'),
    ('San Diego', 10, 71, 0.5, 'Calm'),
    ('San Diego', 11, 64, 1.1, 'Calm'),
    ('San Diego', 12, 59, 1.8, 'Calm'),
    ('San Diego', 1, 57, 2.2, 'Moderate'),
    ('Seattle', 10, 53, 3.2, 'Rough'),
    ('Seattle', 11, 45, 5.8, 'Rough'),
    ('Seattle', 12, 40, 5.5, 'Rough'),
    ('Seattle', 1, 42, 5.2, 'Rough');

-- ==========================================================================
-- Step 2: Join Weather Data with Gaming Performance
-- Business Question: "Does weather at the home port affect casino revenue?"
-- ==========================================================================

SELECT
    pw.port_name AS home_port,
    pw.avg_sea_state,
    pw.avg_temp_f,
    s.brand,
    COUNT(DISTINCT vp.voyage_id) AS num_voyages,
    ROUND(AVG(vp.revenue_per_day), 2) AS avg_daily_revenue,
    ROUND(AVG(vp.revenue_per_passenger), 2) AS avg_rev_per_passenger,
    ROUND(AVG(vp.unique_players), 0) AS avg_players_per_voyage
FROM ANALYTICS.VOYAGE_PERFORMANCE vp
JOIN RAW_GAMING.SHIPS s ON vp.ship_name = s.ship_name
JOIN COLLABORATION.PORT_WEATHER pw 
    ON s.home_port = pw.port_name
    AND MONTH(vp.departure_date) = pw.month_num
GROUP BY pw.port_name, pw.avg_sea_state, pw.avg_temp_f, s.brand
ORDER BY avg_daily_revenue DESC;

-- ==========================================================================
-- Step 3: Sea Days vs Port Days Revenue Analysis
-- Business Question: "Do passengers gamble more on sea days?"
-- ==========================================================================

SELECT
    vp.ship_name,
    vp.brand,
    vp.itinerary_name,
    vp.sea_days,
    vp.port_days,
    ROUND(vp.sea_days::FLOAT / (vp.sea_days + vp.port_days) * 100, 1) AS pct_sea_days,
    vp.house_revenue,
    vp.revenue_per_day,
    vp.revenue_per_passenger
FROM ANALYTICS.VOYAGE_PERFORMANCE vp
ORDER BY vp.revenue_per_day DESC;

-- Correlation: more sea days = more revenue?
SELECT
    ROUND(CORR(sea_days::FLOAT / (sea_days + port_days), revenue_per_day), 3) 
        AS sea_day_revenue_correlation,
    ROUND(CORR(sea_days::FLOAT / (sea_days + port_days), unique_players), 3) 
        AS sea_day_player_correlation
FROM ANALYTICS.VOYAGE_PERFORMANCE;

/*
  KEY INSIGHT: Data Collaboration enables you to enrich your proprietary 
  gaming data with external datasets (weather, demographics, economic data)
  WITHOUT moving or copying data. In a production scenario, you would:
  
  1. Subscribe to a Weather Source dataset on the Marketplace
  2. Join it directly with your gaming data in real-time
  3. Build richer analytics (e.g., "rough seas = more time in casino")
  
  This is zero-copy data sharing -- the provider maintains the data,
  and you query it live without ETL pipelines.
*/
