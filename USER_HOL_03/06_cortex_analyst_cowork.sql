/*=============================================================================
  Section 6: Conversational BI with Cortex Analyst and CoWork
  Carnival Gaming HOL -- User 03
  
  In this section you will:
  - Create a semantic view from a YAML definition
  - Set up a Cortex Analyst agent in Snowflake CoWork (Intelligence)
  - Ask natural language questions about casino revenue and performance
=============================================================================*/

USE ROLE HOL_USER_03_ROLE;
USE WAREHOUSE HOL_USER_03_WH;
USE DATABASE HOL_USER_03_DB;

-- ==========================================================================
-- Step 1: Create a stage and upload the semantic model YAML
-- ==========================================================================

CREATE STAGE IF NOT EXISTS GOLD.SEMANTIC_MODELS
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for Cortex Analyst semantic model YAML files';

-- IMPORTANT: Upload the semantic_model.yaml file to this stage.
--
-- Option A (Snowsight UI): 
--   1. Navigate to Data > HOL_USER_03_DB > GOLD > Stages
--   2. Click on SEMANTIC_MODELS
--   3. Click "+ Files" and upload semantic_model.yaml from your workspace folder
--
-- Option B (SnowSQL/CLI):
--   PUT file://./semantic_model.yaml @HOL_USER_03_DB.GOLD.SEMANTIC_MODELS
--     AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Verify the file was uploaded
LIST @GOLD.SEMANTIC_MODELS;

-- ==========================================================================
-- Step 2: Create the Semantic View from the YAML
-- ==========================================================================

-- Read the YAML from stage and create the semantic view
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'HOL_USER_03_DB.GOLD.GAMING_SEMANTIC_MODEL',
    (SELECT TO_VARCHAR(GET_PRESIGNED_URL(@GOLD.SEMANTIC_MODELS, 'semantic_model.yaml')))
);

-- If the above errors, try this alternative approach:
-- Read YAML content directly from stage and pass it
/*
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'HOL_USER_03_DB.GOLD.GAMING_SEMANTIC_MODEL',
    (SELECT $1 FROM @GOLD.SEMANTIC_MODELS/semantic_model.yaml (FILE_FORMAT => (TYPE = 'CSV' FIELD_DELIMITER = NONE RECORD_DELIMITER = NONE)))
);
*/

-- Verify the semantic view was created
DESCRIBE SEMANTIC VIEW GOLD.GAMING_SEMANTIC_MODEL;

-- ==========================================================================
-- Step 3: Set up CoWork (Snowflake Intelligence)
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
--    - Name: "Casino Analytics - User 03"
--    - Warehouse: HOL_USER_03_WH
--    - Add your semantic view: HOL_USER_03_DB.GOLD.GAMING_SEMANTIC_MODEL
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
-- Step 4: Query the semantic view directly with SQL
-- ==========================================================================

-- You can also query the semantic view directly using SEMANTIC_VIEW()
SELECT * FROM SEMANTIC_VIEW(
    GOLD.GAMING_SEMANTIC_MODEL
    DIMENSIONS DAILY_SHIP_REVENUE.brand
    METRICS DAILY_SHIP_REVENUE.total_revenue, DAILY_SHIP_REVENUE.total_amount_wagered
);

-- Revenue by game type
SELECT * FROM SEMANTIC_VIEW(
    GOLD.GAMING_SEMANTIC_MODEL
    DIMENSIONS DAILY_SHIP_REVENUE.game_type
    METRICS DAILY_SHIP_REVENUE.total_revenue, DAILY_SHIP_REVENUE.avg_house_edge
);
