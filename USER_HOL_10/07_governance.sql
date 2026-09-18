/*=============================================================================
  Section 7: Data Governance
  Carnival Gaming HOL -- User 10
  
  In this section you will:
  - Tag sensitive player data (PII) with object tags
  - Create dynamic data masking policies to protect PII
  - Create a row access policy to restrict data by brand
  - See how governance controls work transparently
=============================================================================*/

USE ROLE HOL_USER_10_ROLE;
USE WAREHOUSE HOL_USER_10_WH;
USE DATABASE HOL_USER_10_DB;

-- ==========================================================================
-- Step 1: Create Tags for Data Classification
-- ==========================================================================

USE SCHEMA RAW_GAMING;

CREATE OR REPLACE TAG PII_TYPE
  ALLOWED_VALUES 'NAME', 'EMAIL', 'PHONE'
  COMMENT = 'Identifies columns containing Personally Identifiable Information';

CREATE OR REPLACE TAG SENSITIVITY_LEVEL
  ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL'
  COMMENT = 'Data sensitivity classification';

-- ==========================================================================
-- Step 2: Apply Tags to Columns and Tables
-- ==========================================================================

-- Tag PII columns on the PLAYERS table
ALTER TABLE PLAYERS MODIFY COLUMN first_name SET TAG PII_TYPE = 'NAME';
ALTER TABLE PLAYERS MODIFY COLUMN last_name SET TAG PII_TYPE = 'NAME';
ALTER TABLE PLAYERS MODIFY COLUMN email SET TAG PII_TYPE = 'EMAIL';
ALTER TABLE PLAYERS MODIFY COLUMN phone SET TAG PII_TYPE = 'PHONE';

-- Tag tables with sensitivity levels
ALTER TABLE PLAYERS SET TAG SENSITIVITY_LEVEL = 'CONFIDENTIAL';
ALTER TABLE GAMING_TRANSACTIONS SET TAG SENSITIVITY_LEVEL = 'INTERNAL';
ALTER TABLE SHIPS SET TAG SENSITIVITY_LEVEL = 'PUBLIC';
ALTER TABLE CASINO_GAMES SET TAG SENSITIVITY_LEVEL = 'PUBLIC';

-- Verify tags are applied
SELECT * FROM TABLE(
    INFORMATION_SCHEMA.TAG_REFERENCES('HOL_USER_10_DB.RAW_GAMING.PLAYERS', 'TABLE')
);

-- ==========================================================================
-- Step 3: Create Dynamic Data Masking Policies
-- ==========================================================================

-- Masking policy for email: show full email to owner role, mask for others
CREATE OR REPLACE MASKING POLICY EMAIL_MASK AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() = 'HOL_USER_10_ROLE' THEN val
        ELSE REGEXP_REPLACE(val, '.+@', '***@')
    END;

-- Masking policy for phone: show full phone to owner role, mask for others
CREATE OR REPLACE MASKING POLICY PHONE_MASK AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() = 'HOL_USER_10_ROLE' THEN val
        ELSE '***-***-' || RIGHT(val, 4)
    END;

-- Masking policy for names: show full name to owner role, mask for others
CREATE OR REPLACE MASKING POLICY NAME_MASK AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() = 'HOL_USER_10_ROLE' THEN val
        ELSE LEFT(val, 1) || '****'
    END;

-- Apply masking policies to columns
ALTER TABLE PLAYERS MODIFY COLUMN email SET MASKING POLICY EMAIL_MASK;
ALTER TABLE PLAYERS MODIFY COLUMN phone SET MASKING POLICY PHONE_MASK;
ALTER TABLE PLAYERS MODIFY COLUMN first_name SET MASKING POLICY NAME_MASK;
ALTER TABLE PLAYERS MODIFY COLUMN last_name SET MASKING POLICY NAME_MASK;

-- ==========================================================================
-- Step 4: Test the Masking Policies
-- ==========================================================================

-- As your own role, you should see UNMASKED data
SELECT player_id, first_name, last_name, email, phone, loyalty_tier
FROM PLAYERS
LIMIT 5;

-- The masking policies would mask data for any OTHER role querying this table
-- In a production setting, you would create a separate "analyst" role that
-- sees masked PII while still being able to analyze gaming patterns.

-- ==========================================================================
-- Step 5: Create a Row Access Policy
-- This demonstrates restricting which rows different roles can see
-- ==========================================================================

-- Create a mapping table that controls brand-level access
CREATE OR REPLACE TABLE RAW_GAMING.BRAND_ACCESS_CONTROL (
    role_name VARCHAR,
    brand VARCHAR
);

-- Your role can see both brands
INSERT INTO RAW_GAMING.BRAND_ACCESS_CONTROL VALUES
    ('HOL_USER_10_ROLE', 'Carnival'),
    ('HOL_USER_10_ROLE', 'Holland America');

-- Create the row access policy
CREATE OR REPLACE ROW ACCESS POLICY BRAND_ROW_POLICY
AS (brand_col VARCHAR) RETURNS BOOLEAN ->
    EXISTS (
        SELECT 1 FROM RAW_GAMING.BRAND_ACCESS_CONTROL
        WHERE role_name = CURRENT_ROLE()
          AND brand = brand_col
    );

-- Apply to the SHIPS table
ALTER TABLE SHIPS ADD ROW ACCESS POLICY BRAND_ROW_POLICY ON (brand);

-- Verify: you should see all 12 ships (both brands)
SELECT ship_name, brand FROM SHIPS ORDER BY brand, ship_name;

-- ==========================================================================
-- Step 6: Review Your Governance Posture
-- ==========================================================================

-- See all tags in your database
SHOW TAGS IN SCHEMA RAW_GAMING;

-- See all masking policies
SHOW MASKING POLICIES IN SCHEMA RAW_GAMING;

-- See all row access policies  
SHOW ROW ACCESS POLICIES IN SCHEMA RAW_GAMING;

/*
  KEY INSIGHT: Snowflake governance controls are:
  - Transparent: Queries work the same way, policies are enforced automatically
  - Dynamic: Based on the ROLE of the person querying, not static data copies
  - Centralized: Defined once, enforced everywhere the data is accessed
  - Auditable: All policy applications are tracked in INFORMATION_SCHEMA
*/
