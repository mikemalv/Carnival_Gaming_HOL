/*=============================================================================
  Section 6: Conversational BI with Cortex Analyst and CoWork
  Carnival Gaming HOL -- User {{USER_NUM}}
  
  In this section you will:
  - Create a semantic view from a YAML definition
  - Set up a Cortex Analyst agent in Snowflake CoWork (Intelligence)
  - Ask natural language questions about casino revenue and performance
=============================================================================*/

USE ROLE HOL_USER_{{USER_NUM}}_ROLE;
USE WAREHOUSE HOL_USER_{{USER_NUM}}_WH;
USE DATABASE HOL_USER_{{USER_NUM}}_DB;

-- ==========================================================================
-- Step 1: Create a stage and file format for the YAML
-- ==========================================================================

CREATE STAGE IF NOT EXISTS GOLD.SEMANTIC_MODELS
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Stage for Cortex Analyst semantic model YAML files';

CREATE OR REPLACE FILE FORMAT GOLD.YAML_FF
  TYPE = 'CSV' FIELD_DELIMITER = NONE RECORD_DELIMITER = NONE;

-- ==========================================================================
-- Step 2: Copy the semantic model YAML from your workspace to the stage
--
-- semantic_model.yaml already sits in your workspace next to this file,
-- so there is nothing to upload by hand -- COPY FILES moves it for you.
--
-- Note the path says 'versions/head' -- that is the published version of
-- your workspace, which is what you are looking at. ('versions/live' only
-- exists while a workspace has uncommitted edits, so it is not reliable.)
-- If you edit the YAML yourself, run
--   ALTER WORKSPACE HOL_WORKSPACES.PUBLIC.USER_HOL_{{USER_NUM}} COMMIT;
-- to publish your change, then re-run this COPY FILES.
-- ==========================================================================

COPY FILES INTO @GOLD.SEMANTIC_MODELS/
FROM 'snow://workspace/HOL_WORKSPACES.PUBLIC.USER_HOL_{{USER_NUM}}/versions/head/'
FILES = ('semantic_model.yaml');

-- Verify the file arrived
LIST @GOLD.SEMANTIC_MODELS;

-- ==========================================================================
-- Step 3: Create the Semantic View from the YAML
-- This reads the YAML from stage and creates the semantic view object.
-- ==========================================================================

DECLARE
  yaml_str VARCHAR;
BEGIN
  SELECT $1 INTO :yaml_str
  FROM @GOLD.SEMANTIC_MODELS/semantic_model.yaml (FILE_FORMAT => 'GOLD.YAML_FF');
  CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('HOL_USER_{{USER_NUM}}_DB.GOLD', :yaml_str);
END;

-- Verify the semantic view was created
DESCRIBE SEMANTIC VIEW GOLD.GAMING_SEMANTIC_MODEL;

-- ==========================================================================
-- Step 4: Query the semantic view directly with SQL
-- ==========================================================================

-- Revenue by brand
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

-- ==========================================================================
-- Step 5: Create a Cortex Agent -- declaratively, in SQL
--
-- This is the modern approach: instead of clicking through the UI, you
-- define the agent as code. It gets TWO tools:
--   - Casino_Metrics  -> Cortex Analyst over your semantic view (structured)
--   - Review_Search   -> Cortex Search over player reviews   (unstructured)
-- plus data_to_chart so it can visualize answers.
--
-- NOTE: Run Section 5 first -- this agent references GOLD.REVIEW_SEARCH.
-- ==========================================================================

CREATE OR REPLACE AGENT GOLD.CASINO_ANALYST
  COMMENT = 'Casino gaming analytics agent for Carnival and Holland America ships'
  PROFILE = '{"display_name": "Casino Analytics - User {{USER_NUM}}"}'
  FROM SPECIFICATION
$$
models:
  orchestration: auto

instructions:
  response: "You are a cruise line casino operations analyst. Be concise and always cite the ship or brand a number refers to. Format currency with a dollar sign."
  orchestration: "Use Casino_Metrics for any question about revenue, wagers, players, or voyage performance. Use Review_Search for questions about what guests said, complaints, or opinions."
  sample_questions:
    - question: "What was total gaming revenue by ship?"
    - question: "Compare Carnival vs Holland America gaming revenue"
    - question: "What are guests complaining about in the casino?"

tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "Casino_Metrics"
      description: "Query structured casino gaming metrics: revenue, amount wagered, house edge, player counts, voyage performance, and loyalty tiers for Carnival and Holland America ships. Use for any numeric or aggregate question. Do NOT use for guest opinions or review text."
  - tool_spec:
      type: "cortex_search"
      name: "Review_Search"
      description: "Semantic search over English-language player reviews of onboard casinos. Use to find what guests said about dealers, games, payouts, atmosphere, or pricing. Do NOT use for numeric aggregates."
  - tool_spec:
      type: "data_to_chart"
      name: "data_to_chart"
      description: "Generates charts and visualizations from query results."

tool_resources:
  Casino_Metrics:
    semantic_view: "HOL_USER_{{USER_NUM}}_DB.GOLD.GAMING_SEMANTIC_MODEL"
  Review_Search:
    search_service: "HOL_USER_{{USER_NUM}}_DB.GOLD.REVIEW_SEARCH"
    max_results: "8"
    id_column: "review_id"
$$;

-- Confirm the agent was created
SHOW AGENTS IN SCHEMA GOLD;

DESCRIBE AGENT GOLD.CASINO_ANALYST;

-- ==========================================================================
-- Step 6: Make the agent visible in Snowflake CoWork
--
-- Creating an agent does NOT automatically show it in CoWork.
--
-- This account has a "Snowflake CoWork object" -- an account-level object
-- that holds a curated list of the agents CoWork displays. When that object
-- exists, an agent is only listed if it has been explicitly added to it.
-- (Without the object, CoWork would just show every agent you can access.)
--
-- Your role has been granted MODIFY on that object, so you can register your
-- own agent yourself. You can only add agents you have USAGE on, so you
-- cannot see or touch another user's agent.
--
-- This block is safe to re-run: if your agent is already registered it
-- reports that instead of failing.
-- ==========================================================================

EXECUTE IMMEDIATE $$
BEGIN
  ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    ADD AGENT HOL_USER_{{USER_NUM}}_DB.GOLD.CASINO_ANALYST;
  RETURN 'Agent registered in CoWork. Open ai.snowflake.com and refresh.';
EXCEPTION
  WHEN OTHER THEN
    RETURN 'Not added -- ' || SQLERRM ||
           '   ("already present" means you are already set up.)';
END;
$$;

-- Confirm your agent is in the CoWork list. You will only see agents you
-- have access to, so expect just your own.
SHOW AGENTS IN SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- ==========================================================================
-- Step 7: Chat with your agent in CoWork (Snowflake Intelligence)
--
-- 1. Go to https://ai.snowflake.com (or in Snowsight, "AI & ML" > "Agents")
-- 2. Select "Casino Analytics - User {{USER_NUM}}" from the agent list.
--    If you do not see it, re-run Step 6 and refresh the page.
-- 3. Start asking questions.
--
-- Because the agent has BOTH an Analyst tool and a Search tool, it can
-- answer numeric questions AND questions about guest opinions, and it
-- will pick the right tool automatically.
-- ==========================================================================

/*
  SAMPLE QUESTIONS TO ASK IN COWORK:

  Structured -- routes to Casino_Metrics (Cortex Analyst):
  - "What was total gaming revenue by ship?"
  - "Which game type generates the most revenue?"
  - "Compare Carnival vs Holland America gaming revenue"
  - "What is the average house edge by game type?"
  - "Show me the top 10 players by total amount wagered"
  - "How does revenue vary by player loyalty tier?"
  - "Which voyages had the highest revenue per passenger?"

  Unstructured -- routes to Review_Search (Cortex Search):
  - "What are guests complaining about in the casino?"
  - "What do guests say about the dealers?"
  - "Find reviews about slot machine payouts"
  - "Are there complaints about smoke or ventilation?"

  Combined -- the agent should use both tools:
  - "Which ship has the lowest revenue, and what are guests saying about it?"
  - "Chart revenue by brand and summarize guest sentiment for each"
*/
