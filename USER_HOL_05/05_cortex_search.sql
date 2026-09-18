/*=============================================================================
  Section 5: Semantic Search with Cortex Search
  Carnival Gaming HOL -- User 05
  
  In this section you will:
  - Create a Cortex Search Service over player reviews
  - Perform semantic (meaning-based) searches that go beyond keywords
  - Filter results by ship, brand, and rating
=============================================================================*/

USE ROLE HOL_USER_05_ROLE;
USE WAREHOUSE HOL_USER_05_WH;
USE DATABASE HOL_USER_05_DB;

-- ==========================================================================
-- Step 1: Materialize the AI-enriched reviews into a table
--
-- WHY materialize instead of calling AI_SENTIMENT inside the search
-- service definition? Two reasons:
--   1. Cortex Search change tracking does not support inline AI function
--      calls, so an incremental refresh on that definition can fail.
--   2. Cost. The service refreshes on its TARGET_LAG. If AI_SENTIMENT
--      sits in the definition, you pay to re-score every review on every
--      refresh. Materializing scores each review exactly once.
-- ==========================================================================

CREATE OR REPLACE TABLE GOLD.REVIEWS_FOR_SEARCH AS
SELECT
    r.review_id,
    r.review_text,
    r.rating,
    r.review_date,
    s.ship_name,
    s.brand,
    v.itinerary_name,
    AI_SENTIMENT(r.review_text):categories[0]:sentiment::VARCHAR AS sentiment_category
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
JOIN BRONZE.VOYAGES v ON r.voyage_id = v.voyage_id
WHERE r.language = 'en';

-- Sanity check the labels before indexing them
SELECT sentiment_category, COUNT(*) AS review_count
FROM GOLD.REVIEWS_FOR_SEARCH
GROUP BY sentiment_category
ORDER BY review_count DESC;

-- ==========================================================================
-- Step 2: Create the Cortex Search Service over that table
-- This indexes your review text for semantic search
-- ==========================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE GOLD.REVIEW_SEARCH
  ON review_text
  ATTRIBUTES ship_name, brand, rating, itinerary_name, sentiment_category
  WAREHOUSE = HOL_USER_05_WH
  TARGET_LAG = '1 hour'
AS (
    SELECT
        review_id,
        review_text,
        rating,
        review_date,
        ship_name,
        brand,
        itinerary_name,
        sentiment_category
    FROM GOLD.REVIEWS_FOR_SEARCH
);

-- ==========================================================================
-- Step 3: Search for reviews -- semantic, not just keyword matching!
-- ==========================================================================

-- Search: Find reviews about slot machine payouts
-- Notice: this finds relevant reviews even if they do not contain the exact words
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'HOL_USER_05_DB.GOLD.REVIEW_SEARCH',
        '{
            "query": "slot machines paying out well",
            "columns": ["review_text", "ship_name", "brand", "rating"],
            "limit": 5
        }'
    )
) AS results;

-- Search: Find complaints about dealers
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'HOL_USER_05_DB.GOLD.REVIEW_SEARCH',
        '{
            "query": "rude or unfriendly dealer experience",
            "columns": ["review_text", "ship_name", "brand", "rating"],
            "limit": 5
        }'
    )
) AS results;

-- Search: Find reviews about poker tournaments
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'HOL_USER_05_DB.GOLD.REVIEW_SEARCH',
        '{
            "query": "poker tournament experience on sea days",
            "columns": ["review_text", "ship_name", "brand", "rating"],
            "limit": 5
        }'
    )
) AS results;

-- Search with filter: Only Carnival ship reviews with positive sentiment
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'HOL_USER_05_DB.GOLD.REVIEW_SEARCH',
        '{
            "query": "best casino experience",
            "columns": ["review_text", "ship_name", "rating", "sentiment_category"],
            "filter": {"@eq": {"brand": "Carnival"}},
            "limit": 5
        }'
    )
) AS results;

-- Search with a sentiment filter: negative reviews about payouts.
-- sentiment_category comes from AI_SENTIMENT, so valid values are
-- lowercase: positive | negative | neutral | mixed | unknown
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'HOL_USER_05_DB.GOLD.REVIEW_SEARCH',
        '{
            "query": "payouts and odds",
            "columns": ["review_text", "ship_name", "rating", "sentiment_category"],
            "filter": {"@eq": {"sentiment_category": "negative"}},
            "limit": 5
        }'
    )
) AS results;

/*
  KEY INSIGHT: Notice how Cortex Search finds semantically relevant reviews
  even when the exact search terms are not present in the text. This is 
  fundamentally different from LIKE or CONTAINS -- it understands meaning,
  not just keywords.
  
  Try your own searches! Think about questions a casino operations manager
  might ask about player feedback.
*/
