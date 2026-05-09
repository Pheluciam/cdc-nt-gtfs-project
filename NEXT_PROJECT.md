# NEXT_PROJECT.md — Roadmap for Data Engineering Project #2

> Created at the end of Project #1 (CDC NT Transport).
> This document captures lessons learned, deferred items, and ambitions
> for the next project so I don't have to re-derive them.
>
> First entry: 2026-05-08

---

## Context — who's writing this

Background: BI / Data Analyst with ~4 years of experience (mostly Tableau,
PostgreSQL, some Power BI). Project #1 was my first real Data Engineering
build. It worked, but it had v1 trade-offs — manual pipeline, hand-rolled
surrogate keys, no CI, no tests, no cloud. Project #2 should explicitly
address those gaps so the portfolio shows progression, not just repetition.

---

## What Project #1 demonstrates

Worth keeping in mind for the next project — these are the boxes already ticked:

- End-to-end pipeline: ingestion → PostgreSQL → dbt → Power BI
- Multi-source data integration with composite surrogate keys
- Star schema design with both core star and snowflake dim-to-dim links
- dbt warehouse modelling (staging → intermediate → warehouse → summary)
- Real-world data quirks handled (GTFS extended hours, multi-feed ID collisions)
- Git workflow and version control (introduced mid-project, but used properly going forward)

## What Project #1 doesn't demonstrate (gaps for #2 to fill)

- **Orchestration / automation** — pipeline is manual, button-press operation
- **Cloud-native stack** — local Postgres, not a real warehouse
- **dbt testing** — no `unique` / `not_null` / custom tests
- **dbt packages** — used hand-rolled `||` for surrogate keys instead of `dbt_utils.generate_surrogate_key()`
- **CI/CD** — no GitHub Actions or automated checks
- **Incremental models** — everything rebuilds from scratch on every run
- **Streaming / near-real-time** — purely static GTFS data
- **Production-grade error handling and logging** — none

---

## Headline plan for Project #2

**Cloud-native rebuild of a similar pipeline, with orchestration as the headline feature.**

Working name: *NT Transport — Cloud Pipeline (v2)*. Could re-use the GTFS data
or pick something different, but the GTFS source is well-understood already
which lets the focus stay on the engineering changes rather than the data.

### Suggested stack

| Layer | Tool |
|---|---|
| Source | GTFS (same as v1) — keeps focus on engineering, not data discovery |
| Ingestion | Python (same) — but containerised |
| Orchestration | **Airflow** (the headline new feature) |
| Warehouse | **Snowflake** (free trial tier or Snowflake's free-tier compute) |
| Transformations | dbt (same) — but with `dbt_utils`, tests, packages |
| BI | Tableau OR Power BI Service — explore both for portfolio breadth |
| CI | **GitHub Actions** running `dbt parse` + tests on every push |
| Containerisation | Docker for ingestion + Airflow runtime |

### Headline DAG (Airflow)

```
Monthly schedule:
  1. Download latest GTFS feeds
  2. Validate file integrity (data quality check)
  3. Load into Snowflake staging
  4. dbt build (run + tests)
  5. Refresh BI semantic layer
  6. Slack/email notification on success or failure
  7. Slack/email alert on failure with logs
```

---

## Updated direction (notes from 2026-05-09)

Rethinking Project #2 to lean into my own domain background rather than
re-using GTFS. Key adjustments — to refine over the next few days:

### Domain shift — operations / demand planning / forecasting

Background: 10 years as operations and production coordinator, with hands-on
S&OP and demand planning experience. Project #2 should leverage this rather
than starting from cold on a new domain.

Likely industry framing: **warehousing and distribution** (different from
public transport, plays to my supply-chain background). Possible angles:

- **Demand forecasting pipeline** — historical sales → time-series forecasts,
  inventory recommendations, reorder points
- **Multi-warehouse / multi-SKU operations dashboard** — fulfilment metrics,
  stock-out risk, cycle times
- **S&OP-style scenario comparison** — actuals vs forecast, plan vs reality

Public datasets that suit this domain (to research):

- M5 Forecasting (Walmart) on Kaggle — strong fit, retail demand
- Rossmann Store Sales — store-level sales forecasting
- UCI Online Retail dataset
- Public supply-chain / logistics datasets (BLS, Kaggle, government open data)

### Stack — adjusted from the original sketch

Power BI is **fixed** — many target employers list it as a core requirement,
so it's the right BI tool to keep showcasing.

Tools to deliberately introduce (don't have to use *all* of them — pick 2–3):

- **MS SQL Server** — high signal, very common in enterprise. Pairs well with
  the Microsoft stack (Power BI, Azure). Strong candidate for the warehouse
- **Databricks** — for Spark-based processing, lakehouse pattern, medallion
  architecture exposure. Free Community Edition exists for portfolio work
- **Apache Airflow** — keep this from the original plan. Orchestration is
  the headline skill v2 needs to demonstrate
- **Snowflake** — alternative to MS SQL Server. Pick one based on which
  makes a stronger story for target roles. Could revisit for project #3
- **Cloud service** — Azure is the natural pairing if going MS SQL Server +
  Power BI route (all Microsoft, integrated experience). AWS or GCP if
  going Snowflake + Databricks. Decide once stack is locked

### Architecture pattern — medallion vs star (and others)

Project #1 used a **Kimball star schema** (fact + dim tables). For Project #2,
worth deliberately trying a different pattern to show breadth:

- **Medallion architecture (Bronze → Silver → Gold)** — Databricks-native,
  popular in lakehouse contexts. Bronze = raw, Silver = cleaned/conformed,
  Gold = business-ready. Different conceptual layering than Kimball
- **Kimball dimensional** — what Project #1 used. Strong for BI consumption.
  Could combine with medallion (Gold layer = star schema)
- **Inmon (3NF normalised warehouse)** — older pattern, more normalised, less
  BI-friendly directly. Probably not for project #2
- **Data Vault 2.0** — hub/link/satellite. Powerful for source-system audit
  trails, but complex. Probably project #4+ territory

**Best fit for project #2:** Medallion architecture is the strongest story
if going with Databricks. It's a deliberately different pattern from
project #1, gives a direct interview talking point ("Project #1 used Kimball
star, Project #2 used medallion — here's why each fit its context"), and
exposes me to the lakehouse pattern that's increasingly common in industry.

### Implications for the original Snowflake + Airflow plan

The original plan in this document was *"cloud-native rebuild of GTFS pipeline
with Snowflake + Airflow."* The updated direction suggests:

- **Domain change** — supply chain / demand planning, not transit
- **Stack open** — could be MS SQL Server + Azure + Power BI (Microsoft stack)
  OR Databricks + Snowflake + Airflow (cloud-native modern stack). Trade-off:
  the Microsoft path plays directly to many job-listing requirements; the
  Databricks path is more "cutting-edge DE." Pick based on target roles
- **Architecture** — medallion if going Databricks, otherwise Kimball still
  works fine
- **Headline still Airflow** — orchestration is the headline regardless of stack

### Open questions to resolve before starting Project #2

- Pick the stack: Microsoft path or modern-cloud path?
- Pick the dataset: M5 forecasting, Rossmann, or something else?
- Pick the architecture: medallion (if Databricks) or Kimball (if MS SQL)?
- Will Power BI report be on Power BI Service (cloud-published) or just
  Desktop with screenshots? Service is more impressive but adds setup work
- Bigger or comparable scope to project #1? Don't bite off too much

### Production-grade patterns to introduce (data marts + partitioning)

These two concepts are foundational at production scale and don't appear in
Project #1 because the GTFS dataset is too small to need them. Project #2
should introduce both deliberately as part of the progression story.

**Data marts (pre-aggregated layer):**

- A focused, pre-aggregated table built for one specific dashboard or
  question (e.g., `daily_sales_by_sku`, `weekly_revenue_by_region`)
- BI tools query the mart, not the raw fact table — queries scan thousands
  of rows instead of millions
- In dbt: marts are usually a separate folder (`models/marts/`) downstream
  of warehouse, often materialised as tables (not views) for query speed
- Trade-off: less flexibility (the mart only answers the questions it was
  designed for) for orders-of-magnitude faster queries

**Partitioning:**

- Splits a large table into chunks based on a column — usually date
- Cloud warehouses (Snowflake, BigQuery, Databricks) charge per byte
  scanned, so partitioning is the primary cost-control lever
- A query with `WHERE sale_date BETWEEN '2026-01-01' AND '2026-01-31'`
  on a date-partitioned table only scans January's partition, not the
  whole table
- Pairs naturally with **dbt incremental models** — only build the new
  partition each day rather than rebuilding the entire table

**For Project #2 (demand planning):**

- Use a real demand-planning dataset (M5 / Rossmann) — these have millions
  of rows where partitioning + marts are genuinely necessary, not optional
- Partition fact tables by `sale_date` (or equivalent)
- Build at least one mart per dashboard page as a deliberate pre-aggregation
- Use `dbt incremental` materialisation for fact tables to demonstrate the
  partition-aware load pattern

**Why these matter for portfolio progression:**

- Project #1 = foundational: star schema, dbt layers, BI integration
- Project #2 = production-grade: orchestration, cloud, data marts,
  partitioning, incremental loads
- Project #3 = depending on direction (streaming? ML feature store? a
  third stack?) — keep options open

The progression "I learned the basics in #1, then built the patterns that
matter at production scale in #2" is the strongest narrative for the
3-project portfolio plan.

---

## Three-project portfolio plan

Given the goal is to reach a strong beginner-to-intermediate Data Engineer
level (not full senior DE) across three projects, here's a sketch of what
each project should *uniquely* demonstrate:

| Project | Headline | New things this introduces |
|---|---|---|
| **#1 — CDC NT Transport** (done) | End-to-end pipeline | dbt layers, star schema, multi-source surrogate keys, BI integration |
| **#2 — Demand planning** (next) | Production-grade pipeline | Cloud warehouse, orchestration, data marts, partitioning, incremental loads, possibly medallion architecture |
| **#3 — TBD** | Depends on what feels weakest after #2 | Options: streaming, ML feature store, multi-cloud, or deeper specialisation in #2's stack |

The goal isn't a comprehensive DE portfolio (3 projects can't cover
everything DE-related). It's a **credible progression story** — each
project demonstrably more capable than the last, with intentional scope
choices documented along the way.

---

## Things to bring forward from Project #1

These are deliberate carry-forwards, not assumed defaults. Each one is a thing
this project did *wrong* or *not at all* that the next project should fix from
day one.

### From day 1 (already in `LEARNINGS.md` carry-forward — listed here for completeness)

1. **Git initialised and pushed to GitHub before writing any code.** First
   commit is the empty repo, second is the basic project structure
2. **`LEARNINGS.md` and `README.md` created day 1**, updated as I go
3. **dbt tests on every dim's primary key** — `unique` and `not_null` at minimum
4. **Source identifiers carried through every layer** if combining multiple sources
5. **Naming conventions decided and documented** before building any models
6. **Use `dbt_utils.generate_surrogate_key`** instead of manual concatenation
7. **Orchestration designed in from day 1** — Airflow DAG with proper failure handling
8. **Verify column units against actual data on ingestion** — don't trust the column-name suffix
9. **Default to `::INTERVAL` for time math** when source data may include extended hours
10. **All display logic in dbt**, not BI tools (with exceptions for tool-specific cosmetics — see LEARNINGS for the line)

### New items specifically for Project #2

These didn't come up in v1 because the project was too small or too local:

- **Containerisation.** Wrap the Python ingestion in a Docker container so it runs identically anywhere
- **Secrets management.** Use Airflow connections / environment variables instead of `.env` files. Document the pattern
- **Logging and observability.** Structured logs (JSON), error monitoring, alerting on failure
- **Backfill strategy.** What happens if I miss a monthly run? How do I catch up cleanly?
- **Schema evolution.** What if the source feed changes (new column, renamed column)? Plan for it
- **Documentation site.** Use `dbt docs generate` and host on GitHub Pages. Free, professional, and shows the entire data lineage automatically
- **CI/CD with GitHub Actions.**
   - `dbt parse` on every push
   - `dbt build` on PR (would need a test data warehouse or seed data)
   - SQL linting with `sqlfluff`
   - Build status badge in README
- **Architecture diagram in README** (Mermaid) — front-of-house framing for the project
- **Power BI Format Painter** — efficiency tool I didn't use on v1 but should default to on v2.
  Click a formatted visual → Home → Format Painter → click another visual → all formatting
  copies across (font sizes, colours, padding, titles). Saves significant time when formatting
  KPI card rows or matching chart styles across pages. Use as the default workflow rather than
  reformatting each visual individually
- **Architectural decision tracking — DAX vs warehouse vs marts.** Project #1 ended with a
  loose principle: dbt for things any consumer would benefit from, DAX for tool-specific
  cosmetic preferences. Project #2 should be more deliberate about this from day one. For each
  presentation-layer decision (sort orders, display names, derived metrics, calculated columns):
  - **In dbt warehouse?** If the logic is data normalisation that any consumer benefits from
  - **In dbt marts/summary?** If it's pre-aggregation specific to BI consumption
  - **In Power BI DAX?** If it's a one-tool, one-dashboard cosmetic preference
  - **Accept the tool default?** If the polish-cost outweighs the benefit
  Capture each call in `LEARNINGS.md` with a one-liner explaining why that layer was chosen.
  This makes the architectural reasoning visible — useful for code review and self-reference

---

## Things to do mid-Project #2 (good habits to build)

- **Commit at every meaningful step.** Don't let work pile up
- **Write tests as you build models, not at the end.** Catches bugs at warehouse layer instead of at BI
- **Update `LEARNINGS.md` mid-project, not just at the end.** Capture details while fresh
- **Use feature branches** for non-trivial changes. Even solo, this builds Git muscle that real teams expect
- **Tag releases** (e.g., `v0.1` first working pipeline, `v1.0` first complete deliverable). Shows version-discipline thinking

---

## What "shippable" should mean for Project #2

Higher bar than v1:

- ✅ Pipeline runs end-to-end automatically (Airflow scheduled, not button-pressed)
- ✅ All dbt models have at least basic tests
- ✅ CI passing on `main` branch (green badge in README)
- ✅ Architecture diagram in README
- ✅ Cloud warehouse, not local
- ✅ Documented secrets management
- ✅ At least one screenshot or live link of the BI output
- ✅ `LEARNINGS.md` populated as I go
- ✅ Repo public on GitHub from day 1

---

## Time / scope expectations

Project #1 took ~4 sessions of focused work. Project #2 will likely take longer
because:

- **Cloud setup overhead** — Snowflake account, Airflow setup, Docker. First time on these will eat time
- **CI/CD learning curve** — first GitHub Actions workflow always takes longer than expected
- **Higher polish bar** — more polish = more time

**Rough estimate:** 8–12 hours of focused work, spread across 5–8 sessions.
Don't rush it. The point of v2 is to demonstrate growth, not speed.

---

## Things explicitly NOT trying to do in Project #2

To avoid scope creep:

- ❌ **Don't try to learn 5 new tools at once.** Pick the headline (Airflow + Snowflake) and execute well. PySpark, Databricks, AWS, etc. wait for project #3+
- ❌ **Don't redesign the data model from scratch.** Re-use the v1 GTFS schema where it makes sense. Focus on engineering changes, not data discovery
- ❌ **Don't build a "perfect" dashboard.** v2's BI output is supporting evidence, not the headline. The headline is the orchestrated pipeline

---

## Cross-references

- `LEARNINGS.md` — full lessons-learned journal from Project #1
- `PROJECT_CONTEXT.md` — current state and immediate next steps for Project #1
- `README.md` — project intro for hiring managers (will be expanded as part of Project #1's shippable phase)

---

## Future projects beyond #2

Sketches only — keep options open:

- **Project #3:** streaming pipeline (Kafka → dbt streaming or similar). Different from #2's batch-orchestrated pattern
- **Project #4:** ML feature store / feature pipeline. Bridge between data engineering and ML
- **Project #5:** multi-cloud (or different cloud — Azure, GCP). Demonstrates portability
- Or: revisit / improve any of the above based on what feels weakest in the portfolio at that point
