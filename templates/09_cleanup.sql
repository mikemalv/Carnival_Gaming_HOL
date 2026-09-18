/*=============================================================================
  Section 9: Cleanup
  Carnival Gaming HOL -- User {{USER_NUM}}
  
  Run this script to clean up all objects created during the lab.
  This is OPTIONAL -- only run if instructed to do so.
=============================================================================*/

USE ROLE HOL_USER_{{USER_NUM}}_ROLE;
USE WAREHOUSE HOL_USER_{{USER_NUM}}_WH;
USE DATABASE HOL_USER_{{USER_NUM}}_DB;

-- ==========================================================================
-- Drop the schemas. CASCADE removes everything inside them in the right
-- order: dynamic tables, views, the search service, the semantic view,
-- tables, tags, and masking / row access policies -- including policy
-- attachments. You do NOT need to detach policies first.
-- ==========================================================================

DROP SCHEMA IF EXISTS COLLABORATION CASCADE;
DROP SCHEMA IF EXISTS GOLD CASCADE;
DROP SCHEMA IF EXISTS SILVER CASCADE;
DROP SCHEMA IF EXISTS BRONZE CASCADE;

-- Suspend warehouse to stop billing
ALTER WAREHOUSE HOL_USER_{{USER_NUM}}_WH SUSPEND;

SELECT 'Cleanup complete for User {{USER_NUM}}!' AS status;
