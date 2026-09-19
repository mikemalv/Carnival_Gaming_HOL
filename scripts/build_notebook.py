#!/usr/bin/env python3
"""
Build templates/09_snowpark_notebook.ipynb.

Kept as a builder rather than hand-edited JSON so cell ids stay unique and the
nbformat structure is always valid. Re-run after editing the cell list below:

    python3 scripts/build_notebook.py
"""

import json
import uuid
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "templates" / "09_snowpark_notebook.ipynb"

U = "{{USER_NUM}}"


def cid() -> str:
    return uuid.uuid4().hex[:8]


def md(text: str) -> dict:
    return {
        "cell_type": "markdown",
        "id": cid(),
        "metadata": {},
        "source": text.strip("\n").splitlines(keepends=True),
    }


def py(name: str, code: str) -> dict:
    return {
        "cell_type": "code",
        "id": cid(),
        "execution_count": None,
        "metadata": {"language": "python", "name": name},
        "outputs": [],
        "source": code.strip("\n").splitlines(keepends=True),
    }


cells = [
    md(f"""
# Section 9: Python and Snowpark

Carnival Gaming HOL -- User {U}

Everything so far has been SQL. This section does the same kind of work in
**Python with the Snowpark DataFrame API**, which is how you would build this
logic inside a data application, a stored procedure, or a scheduled job.

**What you will learn:**

- How Snowpark DataFrames are **lazy** -- they build SQL, they do not move data
- `select` / `filter` / `join` / `group_by` / `agg` on your gaming tables
- Window functions to rank players within each brand
- Writing results back to a Snowflake table
- Registering a **Python UDF** and calling it from a DataFrame
- Calling **Cortex AI functions** from Snowpark
- Charting results with matplotlib

**Before you start:** run **Section 1** and **Section 2** first. This notebook
reads the BRONZE tables and the dynamic tables they create.

> **Pick a warehouse** in the notebook toolbar before running: `HOL_USER_{U}_WH`.
> If `import matplotlib` fails, add it from the **Packages** menu at the top of
> the notebook.
"""),

    py("setup", f"""
# In a Snowflake notebook the session already exists -- just grab it.
from snowflake.snowpark.context import get_active_session

session = get_active_session()

# Pin the context so every unqualified name resolves to your own database.
session.use_role("HOL_USER_{U}_ROLE")
session.use_warehouse("HOL_USER_{U}_WH")
session.use_database("HOL_USER_{U}_DB")
session.use_schema("BRONZE")

print("Role:      ", session.get_current_role())
print("Warehouse: ", session.get_current_warehouse())
print("Database:  ", session.get_current_database())
print("Schema:    ", session.get_current_schema())
"""),

    md("""
## 1. DataFrames are lazy

`session.table(...)` does **not** pull any rows into the notebook. It returns a
DataFrame that represents a query. Nothing runs until you call an *action* like
`.show()`, `.count()`, or `.to_pandas()`.

That is the whole point: the data stays in Snowflake and the compute happens
there. You are writing Python that generates SQL.
"""),

    py("lazy_dataframe", """
txns = session.table("GAMING_TRANSACTIONS")

# Still nothing executed -- this just prints the schema Snowpark inferred.
print("Columns:", txns.columns)

# Look at the SQL Snowpark will send. No data is fetched here either.
print("\\nGenerated SQL:")
print(txns.queries["queries"][0])
"""),

    py("first_action", """
# .count() is an action, so THIS is the first thing that actually runs.
print(f"{txns.count():,} transactions")

# .show() prints a bounded preview. It runs in the warehouse but only
# returns the rows you asked for.
txns.show(5)
"""),

    md("""
## 2. select, filter, and column expressions

`col("X")` refers to a column. Comparisons build expressions rather than
evaluating immediately, which is why you use `&` and `|` (not `and` / `or`)
to combine them, and why each condition needs its own parentheses.
"""),

    py("select_filter", """
from snowflake.snowpark.functions import col

high_rollers = (
    txns
    .select("TXN_ID", "PLAYER_ID", "SHIP_ID", "BET_AMOUNT", "PAYOUT_AMOUNT", "NET_REVENUE")
    .filter((col("BET_AMOUNT") >= 250) & (col("PAYOUT_AMOUNT") > col("BET_AMOUNT")))
)

print(f"{high_rollers.count():,} big winning bets")
high_rollers.show(5)
"""),

    md("""
## 3. Joins

The same joins you wrote in SQL, expressed as method calls. Snowpark pushes the
whole thing down as one query.
"""),

    py("joins", """
ships = session.table("SHIPS")
games = session.table("CASINO_GAMES")

enriched = (
    txns
    .join(ships, txns["SHIP_ID"] == ships["SHIP_ID"])
    .join(games, txns["GAME_ID"] == games["GAME_ID"])
    .select(
        txns["TXN_ID"],
        txns["PLAYER_ID"],
        ships["SHIP_NAME"],
        ships["BRAND"],
        games["GAME_TYPE"],
        txns["BET_AMOUNT"],
        txns["NET_REVENUE"],
    )
)

enriched.show(5)
"""),

    md("""
## 4. Aggregation

`group_by(...).agg(...)` maps directly to `GROUP BY`. Note the aliased imports:
`sum` and `round` would otherwise shadow the Python builtins.
"""),

    py("aggregate", """
from snowflake.snowpark.functions import (
    sum as sf_sum,
    avg,
    count,
    count_distinct,
    round as sf_round,
)

by_brand_game = (
    enriched
    .group_by("BRAND", "GAME_TYPE")
    .agg(
        count("*").alias("TXN_COUNT"),
        count_distinct("PLAYER_ID").alias("UNIQUE_PLAYERS"),
        sf_round(sf_sum("BET_AMOUNT"), 2).alias("TOTAL_WAGERED"),
        sf_round(sf_sum("NET_REVENUE"), 2).alias("HOUSE_REVENUE"),
        sf_round(avg("BET_AMOUNT"), 2).alias("AVG_BET"),
    )
    .sort(col("HOUSE_REVENUE").desc())
)

by_brand_game.show(12)
"""),

    md("""
## 5. Window functions

Rank each player by how much they wagered, **within** their brand. This is a
`RANK() OVER (PARTITION BY ... ORDER BY ...)` written in Python.
"""),

    py("window", """
from snowflake.snowpark import Window
from snowflake.snowpark.functions import rank

player_totals = (
    enriched
    .group_by("BRAND", "PLAYER_ID")
    .agg(sf_round(sf_sum("BET_AMOUNT"), 2).alias("TOTAL_WAGERED"))
)

brand_window = Window.partition_by("BRAND").order_by(col("TOTAL_WAGERED").desc())

top_per_brand = (
    player_totals
    .with_column("RANK_IN_BRAND", rank().over(brand_window))
    .filter(col("RANK_IN_BRAND") <= 5)
    .sort("BRAND", "RANK_IN_BRAND")
)

top_per_brand.show(10)
"""),

    md(f"""
## 6. Write results back to Snowflake

`save_as_table` materializes the DataFrame as a real table. Because everything
ran in Snowflake, no rows ever travelled through this notebook.
"""),

    py("save_table", f"""
(
    player_totals
    .with_column("RANK_IN_BRAND", rank().over(brand_window))
    .write.mode("overwrite")
    .save_as_table("HOL_USER_{U}_DB.GOLD.PLAYER_VALUE_SNOWPARK")
)

check = session.table("HOL_USER_{U}_DB.GOLD.PLAYER_VALUE_SNOWPARK")
print(f"Wrote {{check.count():,}} rows to GOLD.PLAYER_VALUE_SNOWPARK")
check.show(5)
"""),

    md("""
## 7. A Python UDF

This is something plain SQL cannot do: ship **your own Python** to Snowflake and
run it next to the data. Here we bucket players into casino tiers.

`is_permanent=False` makes it a temporary UDF for this session, so it needs no
stage and disappears when you disconnect.
"""),

    py("python_udf", """
from snowflake.snowpark.types import StringType, FloatType


def casino_tier(total_wagered: float) -> str:
    \"\"\"Plain Python -- this function body runs inside Snowflake.\"\"\"
    if total_wagered is None:
        return "Unknown"
    if total_wagered >= 20000:
        return "Whale"
    if total_wagered >= 8000:
        return "High Roller"
    if total_wagered >= 2000:
        return "Regular"
    return "Casual"


tier_udf = session.udf.register(
    casino_tier,
    return_type=StringType(),
    input_types=[FloatType()],
    is_permanent=False,
    replace=True,
)

tiered = player_totals.with_column("TIER", tier_udf(col("TOTAL_WAGERED")))

# Your Python function now works like any other SQL function.
(
    tiered
    .group_by("BRAND", "TIER")
    .agg(count("*").alias("PLAYERS"))
    .sort("BRAND", col("PLAYERS").desc())
    .show(12)
)
"""),

    md("""
## 8. Cortex AI functions from Snowpark

The `AI_*` functions from Sections 3-5 are callable from Snowpark too.

Two idioms, and the difference matters:

- **`call_function`** -- for functions that return a plain scalar, like
  `AI_SUMMARIZE`.
- **`sql_expr`** -- the escape hatch for **semi-structured paths**.
  `AI_SENTIMENT` returns an OBJECT, and `:categories[0]:sentiment` is far easier
  to express as a SQL snippet than to build with Python accessors.
"""),

    py("ai_functions", """
from snowflake.snowpark.functions import call_function, sql_expr

reviews = session.table("PLAYER_REVIEWS").filter(col("LANGUAGE") == "en")

scored = (
    reviews
    .join(ships, reviews["SHIP_ID"] == ships["SHIP_ID"])
    .select(
        ships["SHIP_NAME"],
        ships["BRAND"],
        reviews["RATING"],
        reviews["REVIEW_TEXT"],
        # OBJECT return -> pull the overall label out with a SQL path.
        sql_expr("AI_SENTIMENT(review_text):categories[0]:sentiment::varchar").alias("SENTIMENT"),
    )
)

scored.select("SHIP_NAME", "RATING", "SENTIMENT").show(5)
"""),

    py("ai_summarize", """
# call_function works cleanly when the AI function returns a plain string.
(
    reviews
    .filter(col("REVIEW_TEXT").isNotNull())
    .limit(3)
    .select(
        col("REVIEW_TEXT"),
        call_function("AI_SUMMARIZE", col("REVIEW_TEXT")).alias("SUMMARY"),
    )
    .show()
)
"""),

    md("""
## 9. Charting

The rule here matters for cost and speed: **aggregate in Snowflake first, then
call `.to_pandas()` on the small result.** Never pull raw rows into the notebook
just to group them in pandas.
"""),

    py("chart_revenue", """
import matplotlib.pyplot as plt

# Reduce to one row per game type IN SNOWFLAKE, then collect ~6 rows.
by_game = (
    enriched
    .group_by("GAME_TYPE")
    .agg(sf_round(sf_sum("NET_REVENUE"), 2).alias("HOUSE_REVENUE"))
    .sort(col("HOUSE_REVENUE").desc())
    .to_pandas()
)

fig, ax = plt.subplots(figsize=(10, 5))
ax.bar(by_game["GAME_TYPE"], by_game["HOUSE_REVENUE"], color="#29b5e8")
ax.set_title("House Revenue by Game Type")
ax.set_xlabel("Game Type")
ax.set_ylabel("House Revenue ($)")
ax.grid(axis="y", alpha=0.3)
plt.tight_layout()
plt.show()
"""),

    py("chart_sentiment", """
# Sentiment mix per brand -- again, aggregate first, collect a handful of rows.
sentiment_mix = (
    scored
    .group_by("BRAND", "SENTIMENT")
    .agg(count("*").alias("REVIEWS"))
    .to_pandas()
)

pivot = (
    sentiment_mix
    .pivot(index="BRAND", columns="SENTIMENT", values="REVIEWS")
    .fillna(0)
)

fig, ax = plt.subplots(figsize=(10, 5))
bottom = None
for label in [c for c in ["positive", "neutral", "mixed", "negative"] if c in pivot.columns]:
    ax.bar(pivot.index, pivot[label], bottom=bottom, label=label)
    bottom = pivot[label] if bottom is None else bottom + pivot[label]

ax.set_title("Review Sentiment Mix by Brand")
ax.set_ylabel("Reviews")
ax.legend(title="AI_SENTIMENT")
plt.tight_layout()
plt.show()
"""),

    md(f"""
## Recap

You just did the lab's analytics in Python instead of SQL:

| Snowpark | SQL equivalent |
|----------|----------------|
| `session.table("X")` | `FROM X` |
| `.filter(col("A") > 1)` | `WHERE A > 1` |
| `.join(other, on)` | `JOIN` |
| `.group_by(...).agg(...)` | `GROUP BY` |
| `rank().over(Window...)` | `RANK() OVER (...)` |
| `.save_as_table("T")` | `CREATE TABLE T AS ...` |
| `session.udf.register(f)` | `CREATE FUNCTION` |
| `sql_expr("AI_SENTIMENT(...)")` | the AI functions from Section 4 |

The important idea: **the data never left Snowflake.** Snowpark turned your
Python into SQL and ran it on your warehouse. The only rows that reached this
notebook were the small aggregates you charted.

**Next:** `10_cleanup.sql` -- but only run it when your facilitator says so.
Everything in it is commented out by default so you cannot drop your work by
accident.
"""),
]

nb = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {
            "codemirror_mode": {"name": "ipython", "version": 3},
            "file_extension": ".py",
            "mimetype": "text/x-python",
            "name": "python",
            "nbconvert_exporter": "python",
            "pygments_lexer": "ipython3",
            "version": "3.9",
        },
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}

OUT.write_text(json.dumps(nb, indent=1) + "\n", encoding="utf-8")
print(f"wrote {OUT.relative_to(REPO)}  ({OUT.stat().st_size:,} bytes, {len(cells)} cells)")
