/*=============================================================================
  Section 6: Conversational BI with Cortex Analyst and CoWork
  Carnival Gaming HOL -- User 02
  
  In this section you will:
  - Upload a semantic model that describes your gaming data
  - Create a Cortex Analyst agent in Snowflake CoWork (Intelligence)
  - Ask natural language questions about casino revenue and performance
=============================================================================*/

USE ROLE HOL_USER_02_ROLE;
USE WAREHOUSE HOL_USER_02_WH;
USE DATABASE HOL_USER_02_DB;

-- ==========================================================================
-- Step 1: Create a stage for the semantic model
-- ==========================================================================

CREATE STAGE IF NOT EXISTS GOLD.SEMANTIC_MODELS
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for Cortex Analyst semantic model YAML files';

-- ==========================================================================
-- Step 2: Upload the semantic model
-- 
-- IMPORTANT: You need to upload the semantic_model.yaml file to this stage.
-- Option A (Snowsight UI): 
--   1. Navigate to Data > HOL_USER_02_DB > GOLD > Stages
--   2. Click on SEMANTIC_MODELS
--   3. Click "+ Files" and upload semantic_model.yaml from your user folder
--
-- Option B (SnowSQL/CLI):
--   PUT file://./semantic_model.yaml @HOL_USER_02_DB.GOLD.SEMANTIC_MODELS
--     AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- ==========================================================================

-- Verify the file was uploaded
LIST @GOLD.SEMANTIC_MODELS;

-- ==========================================================================
-- Step 3: Create a Semantic View from the YAML
-- ==========================================================================

CREATE OR REPLACE SEMANTIC VIEW GOLD.GAMING_SEMANTIC_MODEL
  FROM @GOLD.SEMANTIC_MODELS/semantic_model.yaml;

-- Verify the semantic view
DESCRIBE SEMANTIC VIEW GOLD.GAMING_SEMANTIC_MODEL;

-- ==========================================================================
-- Step 4: Set up CoWork (Snowflake Intelligence)
--
-- INSTRUCTIONS (done in the Snowsight UI):
--
-- 1. Navigate to: Snowflake Intelligence (CoWork)
--    - Click "AI & ML" in the left sidebar
--    - Select "Snowflake Intelligence" (or "CoWork")
--
-- 2. Click "New" to create a new analyst
--
-- 3. Configure the analyst:
--    - Name: "Casino Analytics - User 02"
--    - Warehouse: HOL_USER_02_WH
--    - Add your semantic view: HOL_USER_02_DB.GOLD.GAMING_SEMANTIC_MODEL
--
-- 4. Click "Create"
--
-- 5. Try asking these questions in the chat:
-- ==========================================================================

/*
  SAMPLE QUESTIONS TO ASK IN COWORK:

  Revenue Analysis:
  - "What was total gaming revenue by ship?"
  - "Which game type generates the most revenue?"
  - "Compare Carnival vs Holland America gaming revenue"
  - "What is the average house edge by game type?"
  
  Player Analysis:
  - "Show me the top 10 players by total amount wagered"
  - "How does revenue vary by player loyalty tier?"
  - "What is the average bet size by game type?"
  
  Voyage Performance:
  - "Which voyages had the highest revenue per passenger?"
  - "How does the number of sea days affect total gaming revenue?"
  - "What itineraries generate the most casino revenue?"
  
  Trend Analysis:
  - "Show daily gaming revenue trends"
  - "Which day of the week has the highest average revenue?"
  - "How many unique players gamble per voyage on average?"
*/

-- ==========================================================================
-- Step 5: You can also query the analyst programmatically via SQL
-- ==========================================================================

-- Test: Ask a question via SQL (returns the generated query)
SELECT SNOWFLAKE.CORTEX.ANALYST(
    'What is total gaming revenue by brand?',
    FROM_TABLE => 'HOL_USER_02_DB.GOLD.GAMING_SEMANTIC_MODEL'
);
