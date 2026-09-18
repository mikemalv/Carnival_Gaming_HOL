# Carnival Cruise Gaming -- Hands-On Lab

Welcome to the **Carnival Cruise Ship Casino Gaming** Hands-On Lab. This lab walks you through the key capabilities of the Snowflake AI Data Cloud using real-world casino gaming data from Carnival and Holland America cruise ships.

You will learn to load data, build automated pipelines, analyze player reviews with AI, search feedback semantically, ask questions in natural language through CoWork, and protect sensitive data with governance controls.

## Prerequisites

- A Snowflake account (provided by your instructor)
- Your assigned user number (e.g., `01`, `02`, ... `10`)
- A web browser with access to [Snowsight](https://app.snowflake.com)

Your instructor will provide:
| Item | Example |
|------|---------|
| Account URL | `https://SFSENORTHAMERICA-HOL_CARNIVAL.snowflakecomputing.com` |
| Username | `HOL_USER_01` |
| Password | *(provided in session)* |
| Your folder | `USER_HOL_01/` |

## Lab Architecture

Each user has an isolated environment:

```
HOL_USER_XX_ROLE   -- Your dedicated role
HOL_USER_XX_WH     -- Your dedicated warehouse (XS, auto-suspend 60s)
HOL_USER_XX_DB     -- Your dedicated database
  RAW_GAMING       -- Raw data loaded from CSV
  HARMONIZED       -- Enriched/joined data (Dynamic Tables)
  ANALYTICS        -- Business-ready aggregations (Dynamic Tables + Views)
```

## Data Model

You will work with casino gaming data from 12 cruise ships across two brands:

| Table | Rows | Description |
|-------|------|-------------|
| SHIPS | 12 | Carnival and Holland America ships (Mardi Gras, Rotterdam, etc.) |
| VOYAGES | 60 | Caribbean, Alaska, Mediterranean cruises |
| CASINO_GAMES | 22 | Slots, blackjack, poker, roulette, craps, baccarat |
| PLAYERS | 500 | Player profiles with loyalty tiers and PII |
| GAMING_TRANSACTIONS | 50,000 | Individual bets with amounts and payouts |
| PLAYER_REVIEWS | 1,000 | Written casino experience reviews |

---

## How to Use This Lab

1. **Log in** to Snowsight with your assigned credentials
2. **Navigate to your folder** in this repo (e.g., `USER_HOL_01/`) -- each folder has its own README with the full walkthrough
3. **Run each SQL file** in order by opening a new Snowsight Worksheet and pasting the contents
4. Follow the instructions and comments in each file

> **Tip:** Each folder has a `README.md` with a table of all files and step-by-step instructions. Each SQL file starts with `USE ROLE`, `USE WAREHOUSE`, and `USE DATABASE` so your context is always set correctly.

---

## Section 1: Warehousing and Data Loading

**File:** `USER_HOL_XX/01_warehousing_and_loading.sql`

**What you will learn:**
- Create a medallion architecture (RAW / HARMONIZED / ANALYTICS schemas)
- Load CSV data from a shared Snowflake stage into your own database
- Explore gaming data with basic SQL queries

**Business context:** Before we can analyze casino operations, we need to ingest the raw data from ship systems into Snowflake. The medallion architecture (raw -> harmonized -> analytics) keeps data organized as it moves from ingestion to business-ready.

**Steps:**
1. Open a new Worksheet in Snowsight
2. Copy the contents of `01_warehousing_and_loading.sql` into the worksheet
3. Run all statements (or run them one section at a time)
4. Verify you see row counts for all 6 tables

**Key queries to examine:**
- Fleet overview by brand
- Revenue by game type
- Carnival vs Holland America comparison

---

## Section 2: Automated Pipelines with Dynamic Tables

**File:** `USER_HOL_XX/02_dynamic_tables.sql`

**What you will learn:**
- Create Dynamic Tables that automatically transform data
- Build a multi-layer pipeline: RAW -> HARMONIZED -> ANALYTICS
- Understand target lag and automatic refresh

**Business context:** Casino operations teams need real-time dashboards. Dynamic Tables automatically keep downstream aggregations in sync when raw data changes -- no scheduling, no stored procedures, no manual refreshes.

**Steps:**
1. Open a new Worksheet and paste `02_dynamic_tables.sql`
2. Run all statements to create 4 Dynamic Tables
3. Run `SHOW DYNAMIC TABLES` to verify they are refreshing
4. Query the analytics layer to see aggregated results

**Dynamic Tables created:**

| Layer | Table | What it does |
|-------|-------|--------------|
| HARMONIZED | GAMING_TRANSACTIONS_H | Joins transactions with ship, game, player, and voyage details |
| HARMONIZED | PLAYER_SUMMARY_H | Aggregates each player's total wagered, won, bet count, favorite game |
| ANALYTICS | DAILY_SHIP_REVENUE | Daily revenue by ship and game type with house edge |
| ANALYTICS | VOYAGE_PERFORMANCE | Per-voyage revenue, revenue per day, revenue per passenger |

---

## Section 3: Exploring LLMs with Cortex Playground

**File:** `USER_HOL_XX/03_cortex_playground.sql`

**What you will learn:**
- Navigate to Cortex Playground in Snowsight
- Compare LLM models side-by-side
- Evaluate model outputs for review summarization

**Business context:** Before deploying AI at scale, you want to experiment with different models to find the best fit. The Playground lets you test prompts interactively without writing SQL.

**Steps:**
1. Run the SQL file to get sample reviews
2. In Snowsight, navigate to **AI & ML > Cortex Playground**
3. Select two models (e.g., `llama3.1-8b` and `mistral-large2`)
4. Paste a sample review and ask the model to summarize it
5. Compare the outputs

---

## Section 4: AI-Powered Analytics with SQL Functions

**File:** `USER_HOL_XX/04_ai_sql_functions.sql`

**What you will learn:**
- Score review sentiment with `SENTIMENT()`
- Classify reviews into categories with `AI_CLASSIFY()`
- Summarize text with `SUMMARIZE()`
- Generate executive briefings with `AI_COMPLETE()`

**Business context:** Casino managers receive thousands of player reviews. AI functions let you instantly process them all -- scoring sentiment, categorizing feedback, and generating summaries -- directly in SQL without external tools.

**Steps:**
1. Paste `04_ai_sql_functions.sql` into a new Worksheet
2. Run the sentiment analysis query -- see which ships rank highest
3. Run the classification query -- understand what players talk about most
4. Run the executive briefing generation
5. Create the `ENRICHED_REVIEWS` view for downstream use

**Cortex AI Functions used:**

| Function | Purpose |
|----------|---------|
| `SENTIMENT()` | Scores text from -1 (negative) to +1 (positive) |
| `AI_CLASSIFY()` | Categorizes text into user-defined labels |
| `SUMMARIZE()` | Creates concise summaries of longer text |
| `AI_COMPLETE()` | Generates new text from a prompt (e.g., briefings) |

---

## Section 5: Semantic Search with Cortex Search

**File:** `USER_HOL_XX/05_cortex_search.sql`

**What you will learn:**
- Create a Cortex Search Service over player reviews
- Perform semantic (meaning-based) searches
- Filter search results by ship, brand, and sentiment

**Business context:** When investigating specific issues (e.g., "are dealers being rude on the Mardi Gras?"), keyword search misses relevant feedback that uses different words. Cortex Search understands meaning, not just keywords.

**Steps:**
1. Paste `05_cortex_search.sql` into a new Worksheet
2. Create the Cortex Search Service (this takes a minute to index)
3. Run the sample search queries
4. Try your own searches -- what would a casino ops manager look for?

**Sample searches to try:**
- `"slot machines paying out well"` -- finds reviews about winning, even without the word "payout"
- `"rude or unfriendly dealer experience"` -- surfaces complaints using various phrasings
- `"poker tournament experience on sea days"` -- finds tournament-related feedback

---

## Section 6: Conversational BI with Cortex Analyst and CoWork

**File:** `USER_HOL_XX/06_cortex_analyst_cowork.sql` + `USER_HOL_XX/semantic_model.yaml`

**What you will learn:**
- Upload a semantic model that describes your gaming data
- Create a Cortex Analyst agent in Snowflake CoWork
- Ask natural language questions about casino performance

**Business context:** Executives and managers should not need to write SQL. Cortex Analyst translates plain-English questions into SQL queries against your semantic model. CoWork provides the chat interface.

**Steps:**
1. Run `06_cortex_analyst_cowork.sql` to create the semantic model stage
2. Upload `semantic_model.yaml` to the `ANALYTICS.SEMANTIC_MODELS` stage:
   - In Snowsight: Data > your DB > ANALYTICS > Stages > SEMANTIC_MODELS > "+ Files"
3. Run the `CREATE SEMANTIC VIEW` statement
4. Navigate to **AI & ML > Snowflake Intelligence (CoWork)**
5. Create a new analyst:
   - Name: `Casino Analytics`
   - Add your semantic view: `HOL_USER_XX_DB.ANALYTICS.GAMING_SEMANTIC_MODEL`
6. Start asking questions!

**Sample questions for CoWork:**
- "What was total gaming revenue by ship?"
- "Which game type generates the highest house edge?"
- "Compare Carnival vs Holland America revenue per passenger"
- "Show me the top 10 players by total wagered"
- "Which itineraries have the best casino performance?"

---

## Section 7: Data Governance

**File:** `USER_HOL_XX/07_governance.sql`

**What you will learn:**
- Tag PII columns (names, email, phone) with object tags
- Create dynamic data masking policies
- Create row access policies to restrict data by brand
- Understand how governance is transparent and role-based

**Business context:** Player data contains PII that must be protected. Governance controls ensure analysts can query gaming patterns without seeing raw personal data, and brand-specific teams only see their own ships.

**Steps:**
1. Paste `07_governance.sql` into a new Worksheet
2. Create tags and apply them to the PLAYERS table
3. Create and apply masking policies
4. Query the PLAYERS table -- you should see unmasked data (your role is authorized)
5. Create and apply the row access policy on SHIPS

**Governance objects created:**

| Object | Type | Purpose |
|--------|------|---------|
| PII_TYPE | Tag | Classifies columns as NAME, EMAIL, or PHONE |
| SENSITIVITY_LEVEL | Tag | Classifies tables as PUBLIC, INTERNAL, or CONFIDENTIAL |
| EMAIL_MASK | Masking Policy | Hides email prefix from unauthorized roles |
| PHONE_MASK | Masking Policy | Shows only last 4 digits to unauthorized roles |
| NAME_MASK | Masking Policy | Shows only first initial to unauthorized roles |
| BRAND_ROW_POLICY | Row Access Policy | Filters ship data by brand based on role |

---

## Section 8: Data Collaboration via Marketplace

**File:** `USER_HOL_XX/08_collaboration.sql`

**What you will learn:**
- Enrich gaming data with external weather/port data
- Analyze how weather affects casino revenue
- Understand zero-copy data sharing concepts

**Business context:** Do passengers gamble more on sea days? Does weather at the home port affect boarding-day casino activity? External data enrichment answers these questions without building ETL pipelines.

**Steps:**
1. Paste `08_collaboration.sql` into a new Worksheet
2. Create the simulated port weather data
3. Join weather data with voyage performance
4. Analyze the correlation between sea days and revenue

---

## Cleanup (Optional)

**File:** `USER_HOL_XX/09_cleanup.sql`

Run this file **only when instructed** to clean up all objects and suspend your warehouse.

---

## Appendix: Snowflake Features Covered

| Section | Features |
|---------|----------|
| 1 - Warehousing | Virtual warehouses, databases, schemas, COPY INTO, stages |
| 2 - Pipelines | Dynamic Tables, target lag, automatic refresh |
| 3 - LLM Playground | Cortex Playground, model comparison |
| 4 - AI Functions | SENTIMENT, AI_CLASSIFY, SUMMARIZE, AI_COMPLETE |
| 5 - Search | Cortex Search Service, semantic search, filtered search |
| 6 - Analyst/CoWork | Semantic models, Cortex Analyst, Snowflake Intelligence (CoWork) |
| 7 - Governance | Object tags, masking policies, row access policies |
| 8 - Collaboration | Data sharing, Marketplace, external data enrichment |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Object does not exist" | Make sure you ran Section 1 first to create schemas and load data |
| "Insufficient privileges" | Verify you are using `HOL_USER_XX_ROLE` (check with `SELECT CURRENT_ROLE()`) |
| Dynamic Table not refreshing | Run `SHOW DYNAMIC TABLES` -- check the `SCHEDULING_STATE` column |
| Cortex Search takes too long | The initial indexing takes 1-2 minutes; subsequent queries are fast |
| CoWork not finding answers | Verify the semantic model YAML was uploaded and the semantic view was created |
| AI functions return errors | Ensure `SNOWFLAKE.CORTEX_USER` role is granted (admin setup handles this) |
