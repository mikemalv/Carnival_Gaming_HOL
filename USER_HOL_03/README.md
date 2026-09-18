# Carnival Cruise Gaming HOL -- User 03

Welcome! This folder contains everything you need for the lab. All SQL files are pre-configured for your Snowflake environment -- just follow the sections below in order.

## Your Environment

| Setting | Value |
|---------|-------|
| Role | `HOL_USER_03_ROLE` |
| Warehouse | `HOL_USER_03_WH` |
| Database | `HOL_USER_03_DB` |

## Where to Find Your Files

Your SQL files are available in **two places** -- use whichever is easier:

**Option A -- Snowflake Workspace (recommended):**
1. In Snowsight, go to **Projects > Workspaces**
2. Open **HOL_WORKSPACES > USER_HOL_03**
3. Click any `.sql` file to open it directly as a worksheet

**Option B -- This GitHub folder:**
1. Click any `.sql` file link below
2. Copy its contents into a new Snowsight SQL Worksheet

## How This Works

For each section below:

1. Open the SQL file (from your workspace or from the link below)
2. **Run the statements top to bottom** (or highlight and run one section at a time)
3. Read the comments in the SQL -- they explain what each step does

> Every SQL file starts with `USE ROLE` / `USE WAREHOUSE` / `USE DATABASE` so your context is always set correctly. You cannot break anyone else's work.

---

## Section 1: Warehousing and Data Loading

**Open:** [01_warehousing_and_loading.sql](01_warehousing_and_loading.sql)

**What you will learn:**
- Create a medallion architecture (BRONZE / SILVER / GOLD schemas)
- Load CSV data from a shared Snowflake stage into your own database
- Explore gaming data with basic SQL queries

**Business context:** Before we can analyze casino operations, we need to ingest the raw data from ship systems into Snowflake. The medallion architecture (bronze -> silver -> gold) keeps data organized as it moves from ingestion to business-ready.

**What to do:**
1. Paste the file into a new Worksheet
2. Run all statements (or run them one section at a time)
3. Verify you see row counts for all 6 tables at the end

**Key queries to look at:**
- Fleet overview (all 12 ships across both brands)
- Revenue by game type (which games make the most money?)
- Carnival vs Holland America comparison

---

## Section 2: Automated Pipelines with Dynamic Tables

**Open:** [02_dynamic_tables.sql](02_dynamic_tables.sql)

**What you will learn:**
- Create Dynamic Tables that automatically transform data
- Build a multi-layer pipeline: BRONZE -> SILVER -> GOLD
- Understand target lag and automatic refresh

**Business context:** Casino operations teams need real-time dashboards. Dynamic Tables automatically keep downstream aggregations in sync when raw data changes -- no scheduling, no stored procedures, no manual refreshes.

**What to do:**
1. Paste the file into a new Worksheet
2. Run all statements to create 4 Dynamic Tables
3. Run `SHOW DYNAMIC TABLES` to verify they are refreshing
4. Query the analytics layer to see aggregated results

**Dynamic Tables you will create:**

| Layer | Table | What it does |
|-------|-------|--------------|
| SILVER | GAMING_TRANSACTIONS_H | Joins transactions with ship, game, player, and voyage details |
| SILVER | PLAYER_SUMMARY_H | Aggregates each player's total wagered, won, bet count, favorite game |
| GOLD | DAILY_SHIP_REVENUE | Daily revenue by ship and game type with house edge |
| GOLD | VOYAGE_PERFORMANCE | Per-voyage revenue, revenue per day, revenue per passenger |

---

## Section 3: Exploring LLMs with Cortex Playground

**Open:** [03_cortex_playground.sql](03_cortex_playground.sql)

**What you will learn:**
- Navigate to Cortex Playground in Snowsight
- Compare LLM models side-by-side
- Evaluate which model gives the best review summaries

**Business context:** Before deploying AI at scale, you want to experiment with different models to find the best fit. The Playground lets you test prompts interactively without writing SQL.

**What to do:**
1. Run the SQL file to get 5 sample player reviews
2. In Snowsight, navigate to **AI & ML > Cortex Playground** (left sidebar)
3. Select two models to compare (e.g., `llama3.1-8b` and `mistral-large2`)
4. Copy a review from your query results and paste it into the Playground
5. Ask the model to summarize it -- compare the two outputs
6. Try changing the system prompt to: *"You are a cruise ship casino operations analyst. Provide concise, actionable summaries of customer feedback."*

---

## Section 4: AI-Powered Analytics with SQL Functions

**Open:** [04_ai_sql_functions.sql](04_ai_sql_functions.sql)

**What you will learn:**
- Score review sentiment with `SNOWFLAKE.CORTEX.SENTIMENT()`
- Classify reviews into business categories with `AI_CLASSIFY()`
- Summarize long reviews with `AI_SUMMARIZE()`
- Generate an executive briefing with `AI_COMPLETE()`

**Business context:** Casino managers receive thousands of player reviews. AI functions let you instantly process them all -- scoring sentiment, categorizing feedback, and generating summaries -- directly in SQL without external tools.

**What to do:**
1. Paste the file into a new Worksheet
2. Run the **sentiment analysis** query -- see which ships rank highest and lowest
3. Run the **classification** query -- understand what players talk about most (Dealer Quality? Game Variety? Atmosphere?)
4. Run the **executive briefing** generation -- AI writes a management summary for you
5. Create the `ENRICHED_REVIEWS` view for use in later sections

**Cortex AI Functions you will use:**

| Function | What it does |
|----------|-------------|
| `SNOWFLAKE.CORTEX.SENTIMENT()` | Scores text from -1.0 (very negative) to +1.0 (very positive) |
| `AI_CLASSIFY()` | Categorizes text into labels you define (e.g., "Dealer Quality", "Wait Times") |
| `AI_SUMMARIZE()` | Creates a concise summary of longer text |
| `AI_COMPLETE()` | Generates new text from a prompt (e.g., management briefings) |

---

## Section 5: Semantic Search with Cortex Search

**Open:** [05_cortex_search.sql](05_cortex_search.sql)

**What you will learn:**
- Create a Cortex Search Service over player reviews
- Perform semantic (meaning-based) searches that go beyond keywords
- Filter search results by ship, brand, and sentiment

**Business context:** When investigating specific issues (e.g., "are dealers being rude on the Mardi Gras?"), keyword search misses relevant feedback that uses different phrasing. Cortex Search understands meaning, not just keywords.

**What to do:**
1. Paste the file into a new Worksheet
2. Run the `CREATE CORTEX SEARCH SERVICE` statement (takes ~1 minute to index)
3. Run the sample search queries and examine the results
4. Try your own searches -- think about what a casino operations manager would look for

**Sample searches to try:**
- `"slot machines paying out well"` -- finds reviews about winning, even without the word "payout"
- `"rude or unfriendly dealer experience"` -- surfaces complaints using various phrasings
- `"poker tournament experience on sea days"` -- finds tournament-related feedback
- `"best casino experience"` with a Carnival-only filter -- shows filtered semantic search

---

## Section 6: Conversational BI with Cortex Analyst and CoWork

**Open:** [06_cortex_analyst_cowork.sql](06_cortex_analyst_cowork.sql) and [semantic_model.yaml](semantic_model.yaml)

**What you will learn:**
- Upload a semantic model that describes your gaming data
- Create a Cortex Analyst agent in Snowflake CoWork (Intelligence)
- Ask natural language questions about casino performance -- no SQL needed

**Business context:** Executives and managers should not need to write SQL. Cortex Analyst translates plain-English questions into SQL queries against your semantic model. CoWork provides the chat interface.

**What to do:**

1. Paste `06_cortex_analyst_cowork.sql` into a new Worksheet
2. Run everything **up through the `CREATE STAGE` statement** (stop there)
3. **Upload the semantic model file:**
   - In Snowsight, navigate to: **Data > HOL_USER_03_DB > GOLD > Stages > SEMANTIC_MODELS**
   - Click **"+ Files"** and upload the [semantic_model.yaml](semantic_model.yaml) file from this folder
4. Go back to your Worksheet and run the remaining statements (`CREATE SEMANTIC VIEW` etc.)
5. **Set up CoWork:**
   - Navigate to **AI & ML > Snowflake Intelligence** (left sidebar)
   - Click **"+ New"** to create a new analyst
   - Name it: `Casino Analytics`
   - Warehouse: `HOL_USER_03_WH`
   - Add your semantic view: `HOL_USER_03_DB.GOLD.GAMING_SEMANTIC_MODEL`
   - Click **Create**
6. **Start asking questions!**

**Sample questions to try in CoWork:**
- "What was total gaming revenue by ship?"
- "Which game type generates the highest house edge?"
- "Compare Carnival vs Holland America gaming revenue"
- "Show me the top 10 players by total wagered"
- "Which itineraries have the best casino performance?"
- "How does revenue vary by player loyalty tier?"
- "What is the average bet size by game type?"

---

## Section 7: Data Governance

**Open:** [07_governance.sql](07_governance.sql)

**What you will learn:**
- Tag PII columns (names, email, phone) with object tags
- Create dynamic data masking policies to protect sensitive data
- Create row access policies to restrict data by brand
- See how governance controls are transparent and role-based

**Business context:** Player data contains PII (names, emails, phone numbers) that must be protected. Governance controls ensure analysts can query gaming patterns without seeing raw personal data, and brand-specific teams only see their own ships.

**What to do:**
1. Paste the file into a new Worksheet
2. Create tags and apply them to the PLAYERS table columns
3. Create and apply masking policies for email, phone, and names
4. Query the PLAYERS table -- you should see **unmasked** data because your role is authorized
5. Create and apply the row access policy on SHIPS
6. Run `SHOW TAGS`, `SHOW MASKING POLICIES`, `SHOW ROW ACCESS POLICIES` to see your governance posture

**What you will create:**

| Object | Type | What it does |
|--------|------|-------------|
| PII_TYPE | Tag | Classifies columns as NAME, EMAIL, or PHONE |
| SENSITIVITY_LEVEL | Tag | Classifies tables as PUBLIC, INTERNAL, or CONFIDENTIAL |
| EMAIL_MASK | Masking Policy | Hides email prefix for unauthorized roles (shows `***@domain.com`) |
| PHONE_MASK | Masking Policy | Shows only last 4 digits for unauthorized roles |
| NAME_MASK | Masking Policy | Shows only first initial for unauthorized roles |
| BRAND_ROW_POLICY | Row Access Policy | Filters ship data by brand based on the querying role |

---

## Section 8: Data Collaboration via Marketplace

**Open:** [08_collaboration.sql](08_collaboration.sql)

**What you will learn:**
- Enrich your gaming data with external weather and port data
- Analyze how weather and sea days affect casino revenue
- Understand zero-copy data sharing concepts

**Business context:** Do passengers gamble more on sea days when they cannot leave the ship? Does rough weather keep passengers indoors at the casino? External data enrichment answers these questions without building ETL pipelines.

**What to do:**
1. Paste the file into a new Worksheet
2. Create the simulated port weather data (in a real scenario, this comes from the Snowflake Marketplace)
3. Join weather data with your voyage performance metrics
4. Look at the correlation between sea days and gaming revenue
5. Compare revenue on rough-sea vs calm-sea voyages

---

## Cleanup (Optional)

**Open:** [09_cleanup.sql](09_cleanup.sql)

Run this file **only when instructed by your lab facilitator.** It drops all objects in your database and suspends your warehouse.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Object does not exist" | Make sure you completed **Section 1** first -- it creates all schemas and loads data |
| "Insufficient privileges" | Run `SELECT CURRENT_ROLE();` -- you should see `HOL_USER_03_ROLE`. If not, run `USE ROLE HOL_USER_03_ROLE;` |
| Dynamic Table not refreshing | Run `SHOW DYNAMIC TABLES IN DATABASE HOL_USER_03_DB;` and check the `SCHEDULING_STATE` column |
| Cortex Search taking a long time | The first indexing takes 1-2 minutes. Subsequent queries are fast. |
| CoWork not finding answers | Verify the `semantic_model.yaml` was uploaded to the stage and the `CREATE SEMANTIC VIEW` ran successfully |
| AI function errors | Ask your instructor to verify the `SNOWFLAKE.CORTEX_USER` database role is granted to `HOL_USER_03_ROLE` |
| Wrong results in queries | Check that you are in the right database: `SELECT CURRENT_DATABASE();` should show `HOL_USER_03_DB` |
