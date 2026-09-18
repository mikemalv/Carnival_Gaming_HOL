/*=============================================================================
  Section 3: Exploring LLMs with Cortex Playground
  Carnival Gaming HOL -- User {{USER_NUM}}
  
  In this section you will:
  - Use the Cortex Playground in Snowsight to experiment with LLMs
  - Compare different models for summarizing player casino reviews
  - Understand how to evaluate model outputs before using them at scale
  
  NOTE: This section is primarily done in the Snowsight UI.
  The SQL below provides sample review text to copy into the Playground.
=============================================================================*/

USE ROLE HOL_USER_{{USER_NUM}}_ROLE;
USE WAREHOUSE HOL_USER_{{USER_NUM}}_WH;
USE DATABASE HOL_USER_{{USER_NUM}}_DB;

/*
  INSTRUCTIONS:
  
  1. In Snowsight, navigate to: AI & ML > Cortex Playground
     (or use the URL: https://app.snowflake.com -- look for "Cortex Playground"
      in the left sidebar under AI & ML)
  
  2. Select TWO models to compare side by side, for example:
     - Left:  llama3.1-8b
     - Right: mistral-large2
  
  3. Copy one of the sample reviews below and paste it into the Playground
  
  4. Try this prompt:
     "Summarize the following cruise casino review in 2 sentences, 
      highlighting the key positive and negative points:
      
      [PASTE REVIEW HERE]"
  
  5. Compare the outputs -- which model gives a more useful summary?
  
  6. Try changing the system prompt to:
     "You are a cruise ship casino operations analyst. Provide concise, 
      actionable summaries of customer feedback."
*/

-- Get some sample reviews to use in the Playground
-- Run this query, then copy individual reviews to paste into the Playground
SELECT review_id, 
       review_text, 
       rating,
       s.ship_name,
       s.brand
FROM BRONZE.PLAYER_REVIEWS r
JOIN BRONZE.SHIPS s ON r.ship_id = s.ship_id
WHERE r.language = 'en'
  AND LENGTH(r.review_text) > 100
ORDER BY RANDOM()
LIMIT 5;

-- You can also try a quick AI_COMPLETE call to compare with the Playground
-- This runs the same type of operation but via SQL
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.1-8b',
    'Summarize this cruise casino review in 2 sentences: ' || review_text
) AS summary,
review_text,
rating
FROM BRONZE.PLAYER_REVIEWS
WHERE language = 'en'
LIMIT 3;
