/*=============================================================================
  Section 4: AI-Powered Analytics with Cortex AI SQL Functions
  Carnival Gaming HOL -- User 10
  
  In this section you will:
  - Analyze player review sentiment with SENTIMENT()
  - Classify reviews into business categories with AI_CLASSIFY()
  - Summarize reviews with SUMMARIZE()
  - Generate a management briefing with AI_COMPLETE()
  - Create an enriched reviews view combining all AI outputs
=============================================================================*/

USE ROLE HOL_USER_10_ROLE;
USE WAREHOUSE HOL_USER_10_WH;
USE DATABASE HOL_USER_10_DB;

-- ==========================================================================
-- Step 1: Sentiment Analysis
-- Business Question: "How do players feel about each ship's casino?"
-- ==========================================================================

SELECT
    s.ship_name,
    s.brand,
    COUNT(*) AS total_reviews,
    ROUND(AVG(AI_SENTIMENT(r.review_text)), 3) AS avg_sentiment,
    ROUND(AVG(CASE WHEN AI_SENTIMENT(r.review_text) >= 0.5 
              THEN AI_SENTIMENT(r.review_text) END), 3) AS avg_positive_score,
    ROUND(AVG(CASE WHEN AI_SENTIMENT(r.review_text) <= -0.5 
              THEN AI_SENTIMENT(r.review_text) END), 3) AS avg_negative_score
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
GROUP BY s.ship_name, s.brand
ORDER BY avg_sentiment DESC;

/*
  KEY INSIGHT: Sentiment Score Ranges
  - Positive: 0.5 to 1.0
  - Neutral:  -0.5 to 0.5
  - Negative: -1.0 to -0.5
  
  Notice how we can instantly score hundreds of reviews with a single SQL query!
*/

-- ==========================================================================
-- Step 2: Classify Customer Feedback
-- Business Question: "What are players commenting on most -- dealer quality,
--                     game variety, atmosphere, or rewards?"
-- ==========================================================================

WITH classified_reviews AS (
    SELECT
        s.ship_name,
        s.brand,
        AI_CLASSIFY(
            r.review_text,
            ['Dealer Quality', 'Game Variety', 'Atmosphere', 'Comps and Rewards', 'Wait Times']
        ):label::VARCHAR AS feedback_category
    FROM BRONZE.PLAYER_REVIEWS r
    JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
    WHERE r.language = 'en'
      AND LENGTH(r.review_text) > 30
)
SELECT
    brand,
    feedback_category,
    COUNT(*) AS number_of_reviews
FROM classified_reviews
GROUP BY brand, feedback_category
ORDER BY brand, number_of_reviews DESC;

-- ==========================================================================
-- Step 3: Summarize Long Reviews
-- Business Question: "Give me quick summaries of our longest reviews"
-- ==========================================================================

SELECT
    r.review_id,
    s.ship_name,
    r.rating,
    AI_SUMMARIZE(r.review_text) AS review_summary,
    r.review_text AS original_review
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND LENGTH(r.review_text) > 100
ORDER BY LENGTH(r.review_text) DESC
LIMIT 10;

-- ==========================================================================
-- Step 4: Generate a Management Briefing
-- Business Question: "Write me an executive summary of casino performance"
-- ==========================================================================

-- First, gather the key metrics
WITH ship_metrics AS (
    SELECT
        s.brand,
        s.ship_name,
        COUNT(DISTINCT r.review_id) AS review_count,
        ROUND(AVG(r.rating), 1) AS avg_rating,
        ROUND(AVG(AI_SENTIMENT(r.review_text)), 2) AS avg_sentiment
    FROM BRONZE.PLAYER_REVIEWS r
    JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
    WHERE r.language = 'en'
    GROUP BY s.brand, s.ship_name
)
SELECT AI_COMPLETE(
    'llama3.1-70b',
    'You are a cruise line casino operations executive. Based on the following ship casino metrics, ' ||
    'write a brief 3-paragraph executive summary highlighting: (1) overall fleet performance, ' ||
    '(2) brand comparison between Carnival and Holland America, and (3) recommended actions. ' ||
    'Metrics: ' || 
    (SELECT LISTAGG(ship_name || ': ' || avg_rating || ' stars, sentiment=' || avg_sentiment || 
     ' (' || review_count || ' reviews)', '; ') FROM ship_metrics)
) AS executive_briefing;

-- ==========================================================================
-- Step 5: Create an Enriched Reviews View
-- Combine sentiment + classification into one reusable view
-- ==========================================================================

CREATE OR REPLACE VIEW GOLD.ENRICHED_REVIEWS AS
SELECT
    r.review_id,
    r.player_id,
    r.review_text,
    r.rating,
    r.review_date,
    r.language,
    s.ship_name,
    s.brand,
    v.itinerary_name,
    AI_SENTIMENT(r.review_text) AS sentiment_score,
    CASE
        WHEN AI_SENTIMENT(r.review_text) >= 0.5 THEN 'Positive'
        WHEN AI_SENTIMENT(r.review_text) <= -0.5 THEN 'Negative'
        ELSE 'Neutral'
    END AS sentiment_category
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
JOIN BRONZE.VOYAGES v ON r.voyage_id = v.voyage_id
WHERE r.language = 'en';

-- Verify the enriched view
SELECT sentiment_category, COUNT(*) AS review_count,
       ROUND(AVG(rating), 1) AS avg_star_rating
FROM GOLD.ENRICHED_REVIEWS
GROUP BY sentiment_category
ORDER BY review_count DESC;
