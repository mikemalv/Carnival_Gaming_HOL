/*=============================================================================
  Section 3: Cortex AI Functions -- Hands-On Sampler
  Carnival Gaming HOL -- User 08
  
  In this section you will try every major Cortex AI function against
  your cruise casino gaming data. Run each query to see the function
  in action before using them at scale in Section 4.
  
  Functions covered:
  - AI_COMPLETE       (text generation / summarization)
  - AI_SENTIMENT      (sentiment scoring)
  - AI_CLASSIFY       (categorization)
  - AI_SUMMARIZE      (one-call summarization)
  - AI_EXTRACT        (structured field extraction)
  - AI_TRANSLATE      (language translation)
  - AI_FILTER         (semantic true/false filtering)
  
  Also includes: Cortex Playground UI walkthrough
=============================================================================*/

USE ROLE HOL_USER_08_ROLE;
USE WAREHOUSE HOL_USER_08_WH;
USE DATABASE HOL_USER_08_DB;

-- ==========================================================================
-- First: grab some sample reviews to work with
-- ==========================================================================

SELECT review_id, review_text, rating, s.ship_name, s.brand
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en' AND LENGTH(r.review_text) > 100
ORDER BY RANDOM()
LIMIT 5;

-- ==========================================================================
-- 1. AI_COMPLETE  --  Text generation and summarization
--    Pass a prompt + model name, get generated text back.
--    Use for: summaries, briefings, rewriting, Q&A, analysis
-- ==========================================================================

-- Summarize a single review
SELECT 
    review_text,
    AI_COMPLETE(
        'llama3.1-8b',
        'Summarize this cruise casino review in one sentence: ' || review_text
    ) AS ai_summary
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en'
LIMIT 3;

-- Generate a management briefing from multiple reviews
SELECT AI_COMPLETE(
    'llama3.1-70b',
    'You are a cruise ship casino operations analyst. Read these 5 player reviews ' ||
    'and write a 3-bullet executive summary of themes and recommended actions:\n\n' ||
    LISTAGG(review_text, '\n---\n') WITHIN GROUP (ORDER BY review_id)
) AS executive_briefing
FROM (
    SELECT review_id, review_text 
    FROM BRONZE.PLAYER_REVIEWS 
    WHERE language = 'en' 
    ORDER BY RANDOM() 
    LIMIT 5
);

-- ==========================================================================
-- 2. AI_SENTIMENT  --  Sentiment scoring (-1 to +1)
--    Returns a float: -1.0 = very negative, 0 = neutral, +1.0 = very positive
--    Use for: satisfaction tracking, alerting on negative trends
-- ==========================================================================

-- Score individual reviews
SELECT 
    review_text,
    rating,
    ROUND(AI_SENTIMENT(review_text), 3) AS sentiment_score,
    CASE
        WHEN AI_SENTIMENT(review_text) >= 0.5 THEN 'Positive'
        WHEN AI_SENTIMENT(review_text) <= -0.5 THEN 'Negative'
        ELSE 'Neutral'
    END AS sentiment_label
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en'
LIMIT 10;

-- Average sentiment by ship
SELECT 
    s.ship_name,
    s.brand,
    COUNT(*) AS review_count,
    ROUND(AVG(AI_SENTIMENT(r.review_text)), 3) AS avg_sentiment,
    ROUND(AVG(r.rating), 1) AS avg_star_rating
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
GROUP BY s.ship_name, s.brand
ORDER BY avg_sentiment DESC;

-- ==========================================================================
-- 3. AI_CLASSIFY  --  Categorize text into labels you define
--    You provide the categories; AI picks the best match.
--    Use for: routing feedback, tagging issues, triage
-- ==========================================================================

-- Classify reviews into operational categories
SELECT 
    review_text,
    AI_CLASSIFY(
        review_text,
        ['Dealer Quality', 'Game Variety', 'Atmosphere', 'Comps and Rewards', 'Wait Times', 'Pricing']
    ):label::VARCHAR AS category,
    rating
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en' AND LENGTH(review_text) > 30
LIMIT 10;

-- Category breakdown by brand
WITH classified AS (
    SELECT
        s.brand,
        AI_CLASSIFY(
            r.review_text,
            ['Dealer Quality', 'Game Variety', 'Atmosphere', 'Comps and Rewards', 'Wait Times', 'Pricing']
        ):label::VARCHAR AS category
    FROM BRONZE.PLAYER_REVIEWS r
    JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
    WHERE r.language = 'en' AND LENGTH(r.review_text) > 30
    LIMIT 200
)
SELECT brand, category, COUNT(*) AS cnt
FROM classified
GROUP BY brand, category
ORDER BY brand, cnt DESC;

-- ==========================================================================
-- 4. AI_SUMMARIZE  --  One-call text summarization (no model selection)
--    Simpler than AI_COMPLETE for pure summarization tasks.
--    Use for: quick summaries without prompt engineering
-- ==========================================================================

SELECT 
    review_text,
    AI_SUMMARIZE(review_text) AS summary
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en' AND LENGTH(review_text) > 80
LIMIT 5;

-- ==========================================================================
-- 5. AI_EXTRACT  --  Pull structured fields from unstructured text
--    Give it text + a list of fields to extract; returns JSON.
--    Use for: extracting entities, amounts, dates, names from text
-- ==========================================================================

-- Extract structured details from reviews
SELECT 
    review_text,
    AI_EXTRACT(
        review_text,
        ['game_mentioned', 'positive_aspect', 'negative_aspect', 'ship_area']
    ) AS extracted_fields
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en' AND LENGTH(review_text) > 80
LIMIT 5;

-- Pull out the extracted values as columns
SELECT 
    review_text,
    AI_EXTRACT(review_text, ['game_mentioned', 'positive_aspect', 'negative_aspect']):game_mentioned::VARCHAR AS game_mentioned,
    AI_EXTRACT(review_text, ['game_mentioned', 'positive_aspect', 'negative_aspect']):positive_aspect::VARCHAR AS positive_aspect,
    AI_EXTRACT(review_text, ['game_mentioned', 'positive_aspect', 'negative_aspect']):negative_aspect::VARCHAR AS negative_aspect
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en' AND LENGTH(review_text) > 80
LIMIT 5;

-- ==========================================================================
-- 6. AI_TRANSLATE  --  Translate text between languages
--    Specify source and target language.
--    Use for: multilingual review analysis, localization
-- ==========================================================================

-- Translate non-English reviews to English
SELECT 
    review_text AS original,
    language,
    AI_TRANSLATE(review_text, language, 'en') AS english_translation
FROM BRONZE.PLAYER_REVIEWS
WHERE language != 'en'
LIMIT 5;

-- Translate an English review to Spanish (for marketing materials)
SELECT 
    review_text,
    AI_TRANSLATE(review_text, 'en', 'es') AS spanish_version
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en' AND rating >= 4
LIMIT 3;

-- ==========================================================================
-- 7. AI_FILTER  --  Semantic true/false filter on text
--    Ask a yes/no question about each row; returns TRUE or FALSE.
--    Use for: finding specific content without keyword guessing
-- ==========================================================================

-- Find reviews that mention winning or jackpots
SELECT review_text, rating, s.ship_name
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND AI_FILTER(r.review_text, 'Does this review mention winning money or hitting a jackpot?')
LIMIT 10;

-- Find reviews that complain about smoke or ventilation
SELECT review_text, rating, s.ship_name
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND AI_FILTER(r.review_text, 'Does this review complain about smoke, smoking, or poor ventilation?')
LIMIT 10;

-- Find reviews that discuss dealer behavior
SELECT review_text, rating, s.ship_name
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND AI_FILTER(r.review_text, 'Does this review specifically comment on dealer behavior or attitude?')
LIMIT 10;

-- ==========================================================================
-- BONUS: Cortex Playground (UI)
-- ==========================================================================

/*
  The Cortex Playground lets you try these same operations interactively:

  1. In Snowsight, navigate to: AI & ML > Cortex Playground
  2. Select TWO models to compare side by side:
     - Left:  llama3.1-8b
     - Right: mistral-large2
  3. Copy a review from the first query above and paste it in
  4. Try prompts like:
     - "Summarize this casino review in 2 sentences"
     - "What game is this person talking about?"
     - "Rate this review's sentiment from 1-10 and explain why"
  5. Try a system prompt: "You are a cruise ship casino operations analyst."
  
  The Playground is great for testing prompts before scaling them with
  AI_COMPLETE in SQL.
*/
