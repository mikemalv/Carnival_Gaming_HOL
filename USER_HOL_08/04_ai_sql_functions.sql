/*=============================================================================
  Section 4: AI-Powered Analytics with Cortex AI SQL Functions
  Carnival Gaming HOL -- User 08
  
  In this section you will:
  - Analyze player review sentiment with AI_SENTIMENT()
  - Classify reviews into business categories with AI_CLASSIFY()
  - Summarize reviews with AI_SUMMARIZE()
  - Generate a management briefing with AI_COMPLETE()
  - Create an enriched reviews view combining all AI outputs
=============================================================================*/

USE ROLE HOL_USER_08_ROLE;
USE WAREHOUSE HOL_USER_08_WH;
USE DATABASE HOL_USER_08_DB;

-- ==========================================================================
-- Step 1: Sentiment Analysis
-- Business Question: "How do players feel about each ship's casino?"
-- ==========================================================================

WITH scored AS (
    SELECT
        r.ship_id,
        AI_SENTIMENT(r.review_text):categories[0]:sentiment::VARCHAR AS sentiment_label
    FROM BRONZE.PLAYER_REVIEWS r
    WHERE r.language = 'en'
)
SELECT
    s.ship_name,
    s.brand,
    COUNT(*) AS total_reviews,
    COUNT_IF(sc.sentiment_label = 'positive') AS positive_reviews,
    COUNT_IF(sc.sentiment_label = 'negative') AS negative_reviews,
    COUNT_IF(sc.sentiment_label = 'mixed')    AS mixed_reviews,
    ROUND(100.0 * COUNT_IF(sc.sentiment_label = 'positive') / COUNT(*), 1) AS pct_positive,
    ROUND(100.0 * COUNT_IF(sc.sentiment_label = 'negative') / COUNT(*), 1) AS pct_negative
FROM scored sc
JOIN BRONZE.SHIPS s ON sc.ship_id = s.ship_id
GROUP BY s.ship_name, s.brand
ORDER BY pct_positive DESC;

/*
  KEY INSIGHT: AI_SENTIMENT returns LABELS, not a number.
  Possible values: positive | negative | neutral | mixed | unknown

  Because it is categorical, you aggregate with COUNT_IF / percentages
  instead of AVG(). 'mixed' is genuinely useful -- it flags reviews that
  praised one thing and complained about another.

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
        ):labels[0]::VARCHAR AS feedback_category
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
WITH scored AS (
    SELECT
        r.ship_id,
        r.review_id,
        r.rating,
        AI_SENTIMENT(r.review_text):categories[0]:sentiment::VARCHAR AS sentiment_label
    FROM BRONZE.PLAYER_REVIEWS r
    WHERE r.language = 'en'
),
ship_metrics AS (
    SELECT
        s.brand,
        s.ship_name,
        COUNT(DISTINCT sc.review_id) AS review_count,
        ROUND(AVG(sc.rating), 1) AS avg_rating,
        ROUND(100.0 * COUNT_IF(sc.sentiment_label = 'positive') / COUNT(*), 0) AS pct_positive
    FROM scored sc
    JOIN BRONZE.SHIPS s ON sc.ship_id = s.ship_id
    GROUP BY s.brand, s.ship_name
)
SELECT AI_COMPLETE(
    'llama3.1-70b',
    'You are a cruise line casino operations executive. Based on the following ship casino metrics, ' ||
    'write a brief 3-paragraph executive summary highlighting: (1) overall fleet performance, ' ||
    '(2) brand comparison between Carnival and Holland America, and (3) recommended actions. ' ||
    'Metrics: ' || 
    (SELECT LISTAGG(ship_name || ' (' || brand || '): ' || avg_rating || ' stars, ' || 
     pct_positive || '% positive sentiment, ' || review_count || ' reviews', '; ') FROM ship_metrics)
) AS executive_briefing;

-- ==========================================================================
-- Step 5: Create an Enriched Reviews Table
-- Combine review detail + AI sentiment into one reusable object.
--
-- NOTE: this is a TABLE, not a VIEW, on purpose. If it were a view, the
-- AI_SENTIMENT call would re-run on every single query against it -- you
-- would pay to re-score all ~860 reviews each time. Materializing scores
-- them once. Re-run this CREATE OR REPLACE when the reviews change.
-- ==========================================================================

CREATE OR REPLACE TABLE GOLD.ENRICHED_REVIEWS AS
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
    AI_SENTIMENT(r.review_text):categories[0]:sentiment::VARCHAR AS sentiment_category
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
JOIN BRONZE.VOYAGES v ON r.voyage_id = v.voyage_id
WHERE r.language = 'en';

-- Verify the enriched table. Sentiment should track the star ratings:
-- 'positive' rows average a high rating, 'negative' rows a low one.
SELECT sentiment_category, COUNT(*) AS review_count,
       ROUND(AVG(rating), 1) AS avg_star_rating
FROM GOLD.ENRICHED_REVIEWS
GROUP BY sentiment_category
ORDER BY review_count DESC;
