/*=============================================================================
  Section 10: Cleanup
  Carnival Gaming HOL -- User 05

  *** EVERY STATEMENT IN THIS FILE IS COMMENTED OUT ON PURPOSE. ***

  This script destroys all the work you did in the lab. Running it by accident
  would wipe out your BRONZE / SILVER / GOLD schemas, your dynamic tables, your
  Cortex Search service, your semantic view, and your agent.

  Nothing here will run as-is. To actually clean up:

    1. Wait until your facilitator tells you the lab is over.
    2. Uncomment the statements below -- select the lines and press
       Cmd+/ (Mac) or Ctrl+/ (Windows) to toggle the comments off.
    3. Run the script.

  If you are unsure, just leave this file alone. An idle warehouse costs
  nothing, and your objects will be removed when the lab account is torn down.
=============================================================================*/


-- ==========================================================================
-- Step 1: Set your context
-- ==========================================================================

-- USE ROLE HOL_USER_05_ROLE;
-- USE WAREHOUSE HOL_USER_05_WH;
-- USE DATABASE HOL_USER_05_DB;


-- ==========================================================================
-- Step 2: Drop the schemas
--
-- CASCADE removes everything inside them in the right order: dynamic tables,
-- views, the Cortex Search service, the semantic view, the agent, tables,
-- tags, and masking / row access policies -- including policy attachments.
-- You do NOT need to detach policies first.
-- ==========================================================================

-- DROP SCHEMA IF EXISTS COLLABORATION CASCADE;
-- DROP SCHEMA IF EXISTS GOLD CASCADE;
-- DROP SCHEMA IF EXISTS SILVER CASCADE;
-- DROP SCHEMA IF EXISTS BRONZE CASCADE;


-- ==========================================================================
-- Step 3: Suspend your warehouse to stop any compute billing
-- ==========================================================================

-- ALTER WAREHOUSE HOL_USER_05_WH SUSPEND;


-- ==========================================================================
-- Step 4: Confirm
-- ==========================================================================

-- SELECT 'Cleanup complete for User 05!' AS status;


-- ==========================================================================
-- Optional: verify nothing is left behind
-- ==========================================================================

-- SHOW SCHEMAS IN DATABASE HOL_USER_05_DB;
