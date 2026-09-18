# Carnival Cruise Gaming HOL -- User 10

Welcome! This is your personal lab folder. All SQL files below are pre-configured for your Snowflake environment:

| Setting | Value |
|---------|-------|
| Role | `HOL_USER_10_ROLE` |
| Warehouse | `HOL_USER_10_WH` |
| Database | `HOL_USER_10_DB` |

## Instructions

Work through the sections in order. Open each SQL file in a **Snowsight Worksheet** and run the statements top to bottom.

| # | File | Section | What You Will Do |
|---|------|---------|-----------------|
| 1 | [01_warehousing_and_loading.sql](01_warehousing_and_loading.sql) | **Warehousing & Loading** | Create schemas, load cruise gaming data from shared stage |
| 2 | [02_dynamic_tables.sql](02_dynamic_tables.sql) | **Dynamic Tables** | Build auto-refreshing pipelines: RAW -> HARMONIZED -> ANALYTICS |
| 3 | [03_cortex_playground.sql](03_cortex_playground.sql) | **Cortex Playground** | Compare LLMs side-by-side for summarizing player reviews |
| 4 | [04_ai_sql_functions.sql](04_ai_sql_functions.sql) | **AI SQL Functions** | Sentiment analysis, classification, summarization, briefing generation |
| 5 | [05_cortex_search.sql](05_cortex_search.sql) | **Cortex Search** | Semantic search over player casino reviews |
| 6 | [06_cortex_analyst_cowork.sql](06_cortex_analyst_cowork.sql) | **Cortex Analyst + CoWork** | Natural language BI -- ask questions about gaming revenue in chat |
| 7 | [07_governance.sql](07_governance.sql) | **Governance** | PII tagging, data masking, row access policies |
| 8 | [08_collaboration.sql](08_collaboration.sql) | **Collaboration** | Enrich gaming data with weather/port data |
| 9 | [09_cleanup.sql](09_cleanup.sql) | **Cleanup** | *(Optional)* Drop all objects and suspend warehouse |

## Section 6 Extra Step

For the Cortex Analyst section, you also need to upload the semantic model file:

1. Run `06_cortex_analyst_cowork.sql` up through the `CREATE STAGE` statement
2. In Snowsight, navigate to: **Data > HOL_USER_10_DB > ANALYTICS > Stages > SEMANTIC_MODELS**
3. Click **"+ Files"** and upload [semantic_model.yaml](semantic_model.yaml) from this folder
4. Return to the worksheet and run the remaining statements
5. Then open **AI & ML > Snowflake Intelligence (CoWork)** to create your analyst

## Tips

- Each file starts with `USE ROLE` / `USE WAREHOUSE` / `USE DATABASE` so your context is always correct
- Run files top-to-bottom, or highlight and run sections one at a time
- If you get "object does not exist", make sure you completed Section 1 first
- Check `SELECT CURRENT_ROLE()` if you get privilege errors
