<img src="assets/hol-banner.svg" alt="Carnival and Holland America - Casino Gaming Analytics Hands-On Lab" width="100%">

# Carnival Cruise Gaming -- Hands-On Lab

This lab walks you through the key capabilities of the **Snowflake AI Data Cloud** using casino gaming data from Carnival and Holland America cruise ships.

## What You Will Build

By the end of this lab, you will have:

- **Loaded** raw gaming data (50K transactions, 1K player reviews, 12 ships) into Snowflake
- **Built automated pipelines** with Dynamic Tables that refresh themselves
- **Experimented with LLMs** in Cortex Playground to compare model outputs
- **Analyzed player sentiment** at scale using AI SQL functions (AI_SENTIMENT, AI_CLASSIFY, AI_SUMMARIZE)
- **Created a semantic search engine** over player casino reviews with Cortex Search
- **Asked business questions in plain English** using Cortex Analyst and Snowflake CoWork
- **Protected player PII** with dynamic masking and row access policies
- **Enriched your data** with external weather data to analyze gaming patterns
- **Rebuilt the analytics in Python** with the Snowpark DataFrame API, a Python UDF, and charts

## Snowflake Features Covered

| Section | Snowflake Capability |
|---------|---------------------|
| 1. Warehousing & Loading | Virtual warehouses, databases, schemas, COPY INTO, stages |
| 2. Dynamic Tables | Declarative data pipelines with automatic refresh |
| 3. Cortex Playground | Side-by-side LLM model comparison |
| 4. AI SQL Functions | AI_SENTIMENT, AI_CLASSIFY, AI_SUMMARIZE, AI_COMPLETE, AI_EXTRACT, AI_FILTER |
| 5. Cortex Search | Semantic (meaning-based) search over unstructured text |
| 6. Cortex Analyst + CoWork | Natural language BI via semantic views and a Cortex Agent |
| 7. Governance | Object tags, dynamic data masking, row access policies |
| 8. Collaboration | Marketplace data sharing, external data enrichment |
| 9. Python & Snowpark | Snowpark DataFrames, window functions, Python UDFs, matplotlib (notebook) |
| 10. Cleanup | Optional teardown -- commented out by default |

## Getting Started

### Step 1: Log in to Snowsight

Your instructor will provide your credentials:

| Item | Example |
|------|---------|
| Account URL | `https://SFSENORTHAMERICA-HOL_CARNIVAL.snowflakecomputing.com` |
| Username | `HOL_USER_01` |
| Password | *(provided in session)* |

### Step 2: Go to your folder

Each user has a dedicated folder with all SQL files pre-configured for your environment. **Click your folder below and follow the README inside it.**

| User | Folder |
|------|--------|
| HOL_USER_01 | [USER_HOL_01/](USER_HOL_01/) |
| HOL_USER_02 | [USER_HOL_02/](USER_HOL_02/) |
| HOL_USER_03 | [USER_HOL_03/](USER_HOL_03/) |
| HOL_USER_04 | [USER_HOL_04/](USER_HOL_04/) |
| HOL_USER_05 | [USER_HOL_05/](USER_HOL_05/) |
| HOL_USER_06 | [USER_HOL_06/](USER_HOL_06/) |
| HOL_USER_07 | [USER_HOL_07/](USER_HOL_07/) |
| HOL_USER_08 | [USER_HOL_08/](USER_HOL_08/) |
| HOL_USER_09 | [USER_HOL_09/](USER_HOL_09/) |
| HOL_USER_10 | [USER_HOL_10/](USER_HOL_10/) |

Everything you need is inside your folder -- a step-by-step README, all SQL files, the Snowpark notebook, and the semantic model YAML. You will not need to come back to this page.

## Data Model

You will work with casino gaming data from 12 cruise ships across two brands:

| Table | Rows | Description |
|-------|------|-------------|
| SHIPS | 12 | Carnival and Holland America ships (Mardi Gras, Rotterdam, etc.) |
| VOYAGES | 60 | Caribbean, Alaska, Mediterranean cruises |
| CASINO_GAMES | 22 | Slots, blackjack, poker, roulette, craps, baccarat |
| PLAYERS | 500 | Player profiles with loyalty tiers |
| GAMING_TRANSACTIONS | 50,000 | Individual bets with amounts and payouts |
| PLAYER_REVIEWS | 1,000 | Written casino experience reviews |
