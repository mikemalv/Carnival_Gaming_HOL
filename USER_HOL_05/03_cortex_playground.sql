/*=============================================================================
  Section 3: Cortex AI Functions -- Hands-On Sampler
  Carnival Gaming HOL -- User 05
  
  In this section you will try every major Cortex AI function against
  your cruise casino gaming data. Run each query to see the function
  in action before using them at scale in Section 4.
  
  Functions covered:
  - AI_COMPLETE       (text generation / summarization)
  - AI_SENTIMENT      (overall + aspect-level sentiment)
  - AI_CLASSIFY       (categorization)
  - AI_SUMMARIZE      (one-call summarization)
  - AI_EXTRACT        (structured field extraction)
  - AI_TRANSLATE      (language translation)
  - AI_FILTER         (semantic true/false filtering)
  
  Also includes: Cortex Playground UI walkthrough
=============================================================================*/

USE ROLE HOL_USER_05_ROLE;
USE WAREHOUSE HOL_USER_05_WH;
USE DATABASE HOL_USER_05_DB;

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
-- 2. AI_SENTIMENT  --  Overall AND aspect-level sentiment
--    Returns an OBJECT, not a number:
--      {"categories":[{"name":"overall","sentiment":"positive"}]}
--    sentiment is one of: positive | negative | neutral | mixed | unknown
--    Use for: satisfaction tracking, alerting on negative trends
-- ==========================================================================

-- 2a. Overall sentiment label for individual reviews.
--     The 'overall' category is always element [0].
SELECT 
    review_text,
    rating,
    AI_SENTIMENT(review_text):categories[0]:sentiment::VARCHAR AS sentiment_label
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en'
LIMIT 10;

-- 2b. Sentiment mix by ship. Because AI_SENTIMENT returns labels (not a float),
--     we count each label instead of averaging a score.
SELECT 
    s.ship_name,
    s.brand,
    COUNT(*) AS review_count,
    COUNT_IF(sentiment_label = 'positive') AS positive_reviews,
    COUNT_IF(sentiment_label = 'neutral')  AS neutral_reviews,
    COUNT_IF(sentiment_label = 'mixed')    AS mixed_reviews,
    COUNT_IF(sentiment_label = 'negative') AS negative_reviews,
    ROUND(100.0 * COUNT_IF(sentiment_label = 'positive') / COUNT(*), 1) AS pct_positive,
    ROUND(AVG(s2.rating), 1) AS avg_star_rating
FROM (
    SELECT 
        r.ship_id,
        r.rating,
        AI_SENTIMENT(r.review_text):categories[0]:sentiment::VARCHAR AS sentiment_label
    FROM BRONZE.PLAYER_REVIEWS r
    WHERE r.language = 'en'
) s2
JOIN BRONZE.SHIPS s ON s2.ship_id = s.ship_id
GROUP BY s.ship_name, s.brand
ORDER BY pct_positive DESC;

-- 2c. ASPECT-LEVEL sentiment -- the real power of AI_SENTIMENT.
--     Pass up to 10 categories and get a sentiment for each one,
--     so you learn WHAT guests liked or disliked, not just whether.
WITH scored AS (
    SELECT 
        r.review_id,
        s.ship_name,
        AI_SENTIMENT(
            r.review_text,
            ['dealer service', 'game variety', 'atmosphere', 'value for money']
        ) AS sentiment
    FROM BRONZE.PLAYER_REVIEWS r
    JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
    WHERE r.language = 'en'
    LIMIT 50
)
SELECT 
    c.value:name::VARCHAR AS aspect,
    COUNT_IF(c.value:sentiment::VARCHAR = 'positive') AS positive,
    COUNT_IF(c.value:sentiment::VARCHAR = 'negative') AS negative,
    COUNT_IF(c.value:sentiment::VARCHAR = 'neutral')  AS neutral,
    COUNT_IF(c.value:sentiment::VARCHAR = 'unknown')  AS not_mentioned
FROM scored, LATERAL FLATTEN(input => scored.sentiment:categories) c
WHERE c.value:name::VARCHAR <> 'overall'
GROUP BY aspect
ORDER BY negative DESC;

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
    ):labels[0]::VARCHAR AS category,
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
        ):labels[0]::VARCHAR AS category
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
    AI_EXTRACT(review_text, ['game_mentioned', 'positive_aspect', 'negative_aspect']):response:game_mentioned::VARCHAR AS game_mentioned,
    AI_EXTRACT(review_text, ['game_mentioned', 'positive_aspect', 'negative_aspect']):response:positive_aspect::VARCHAR AS positive_aspect,
    AI_EXTRACT(review_text, ['game_mentioned', 'positive_aspect', 'negative_aspect']):response:negative_aspect::VARCHAR AS negative_aspect
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
  AND AI_FILTER(PROMPT('Does this review mention winning money or hitting a jackpot? Review: {0}', r.review_text))
LIMIT 10;

-- Find reviews that complain about smoke or ventilation
SELECT review_text, rating, s.ship_name
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND AI_FILTER(PROMPT('Does this review complain about smoke, smoking, or poor ventilation? Review: {0}', r.review_text))
LIMIT 10;

-- Find reviews that discuss dealer behavior
SELECT review_text, rating, s.ship_name
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND AI_FILTER(PROMPT('Does this review specifically comment on dealer behavior or attitude? Review: {0}', r.review_text))
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
