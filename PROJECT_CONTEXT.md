# CDC NT Transport Project — Session Context

> Last updated: 2026-05-07 (end of second session)

## Project overview

- Data Engineering portfolio project for job interviews
- Source data: CDC NT Darwin and Alice Springs GTFS-S (static)
- Stack: Python ingestion → dbt → PostgreSQL → Power BI
- Database: CDC_NT | Warehouse schema: wh_cdc_nt
- Tools: VS Code, pgAdmin 4, dbt, Power BI Desktop
- dbt project path: C:\dbt\cdc_nt_gtfs
- GitHub repo: https://github.com/Pheluciam/cdc-nt-gtfs-project (public)
- Teaching preferences: see `TEACHING_PREFERENCES.md` for how Claude should work with me

## Working habits — standing reminders

> Claude: surface these at the start of each session and prompt me when relevant.

- **Pull at the start of each session** — `git pull` before making changes
- **Git: commit regularly.** After every meaningful change (a fix, a new
  model, a working visual), do a `git add` + `git commit` with a clear
  message. Don't let work pile up uncommitted.
- **Push to GitHub at the end of each session** so the remote repo reflects
  the latest progress (also acts as a backup).
- **README stays current.** If today's session added a new model, dependency,
  or design decision, update `README.md` before pushing.
- **LEARNINGS.md captures takeaways.** At the end of each session — or whenever
  something clicks, breaks, or surprises me — add an entry to `LEARNINGS.md`
  while it's fresh. Short, honest reflections: what worked, what tripped me
  up, what I'd do differently. This is portfolio material and interview prep.

## dbt warehouse models

Fact tables: fact_stop_times, fact_trips, fact_route_summary,
fact_service_days, fact_stop_sequences

Dim tables: dim_agency, dim_calendar, dim_calendar_dates, dim_date,
dim_routes, dim_service_calendar, dim_shapes, dim_stops, dim_trips

Summary tables: route_kpis, trip_kpis, route_service_days,
shape_summary, stop_activity_summary, trip_timebands

## Surrogate key convention

Both source feeds (Darwin and Alice Springs) reuse the same numeric IDs
for different real-world entities, causing duplicate keys when combined.
Resolution: composite surrogate keys built as `feed_id || '_' || natural_id`.

Models updated:

- dim_stops: added `stop_key` (e.g. `darwin_101`, `alice_springs_101`)
- dim_agency: added `agency_key` and `agency_display_name` (clean labels: Darwin, Alice Springs)
- fact_stop_times: added `stop_key` for matching dim_stops
- dim_routes: added `agency_key` for matching dim_agency

Natural keys (route_id, trip_id, service_id, date, agency_id, stop_id)
remain in tables for reference but should not be used for relationships
where a surrogate key exists.

## Power BI — relationships completed

Active (9):

- fact_trips → dim_calendar on service_id
- fact_trips → dim_trips on trip_id
- fact_trips → dim_routes on route_id
- fact_service_days → dim_calendar on service_id
- fact_service_days → dim_date on date
- fact_route_summary → dim_routes on route_id
- fact_stop_times → dim_trips on trip_id
- fact_stop_times → dim_stops on stop_key
- dim_routes → dim_agency on agency_key

Inactive (1):

- dim_trips → dim_calendar on service_id

Star schema verified end-to-end via functional test (agency × route ×
trip count, total = 2070, correctly distributed across both feeds).

## Git status

✅ Repo initialised, .gitignore configured (excludes .env, venvs, target,
   TEACHING_PREFERENCES.md), first commit pushed to GitHub.

Initial commit message: "Initial commit: GTFS ingestion, dbt warehouse with
multi-feed surrogate keys, Power BI star schema"

End-of-session-2 commit pending: needs `git add . && git commit -m "..."
&& git push` covering today's dim_agency display name, LEARNINGS.md
expansion, Power BI Overview page work.

## Dashboard build status

**Locked-in structure:** 4 pages

1. **Overview** — KPIs and headline framing
2. **Network Coverage** — geographic / map page
3. **Service Operations** — frequencies, calendars, time-of-day bands
4. **Multi-Feed Comparison** — Darwin vs Alice Springs side-by-side
   (showcases the multi-feed engineering work)

**Elevator pitch (used as Overview subtitle):**
*"From raw CSVs to interactive dashboard: a complete data engineering
workflow demonstrating ingestion (Python), warehouse modelling
(dbt + PostgreSQL), and BI integration (Power BI), built around real-world
public transport data."*

### Page progress

- ✅ **Page 1 — Overview** structurally complete
  - Title + elevator pitch text boxes
  - 5 KPI cards: Routes (83), Trips (2,070), Stops (768), Stop visits (~50k+), Agencies (2)
  - Trips per Agency bar chart with custom colours per agency
  - Uses `agency_display_name` (Darwin / Alice Springs) for clean labels
  - Minor formatting polish still wanted but not blocking
- ⬜ **Page 2 — Network Coverage** not started
  - Title + subtitle to add
  - Map visual: dim_stops by lat/lon, coloured by feed_id
  - Supporting bars: Routes per Agency, Stops per Agency
- ⬜ **Page 3 — Service Operations** not started
  - Trips by day-of-week (use dim_calendar)
  - Trips by time band (use trip_timebands summary)
  - Weekday vs weekend split
- ⬜ **Page 4 — Multi-Feed Comparison** not started
  - Side-by-side KPIs (Darwin vs Alice Springs)
  - Visual contrast — this is the headline page for the multi-feed engineering story

## Next steps — pick up here next session

### Priority 1 — finish the dashboard

1. **Network Coverage (Page 2)** — title + subtitle + map (lat/lon from dim_stops, coloured by feed_id) + supporting bar charts (routes per agency, stops per agency)
2. **Service Operations (Page 3)** — trips by day-of-week, trips by time band (trip_timebands), weekday vs weekend
3. **Multi-Feed Comparison (Page 4)** — side-by-side KPIs and visuals contrasting Darwin and Alice Springs
4. **Polish pass** — fonts, alignment, colours consistent across all 4 pages, page tab order correct

### Priority 2 — make the project shippable

5. **README.md** — flesh out for hiring managers: overview, stack, architecture, how to run, key design decisions, screenshots of dashboard pages embedded
6. **Dashboard screenshots** — export each page as PNG, embed in README
7. **dbt tests** — add `unique` and `not_null` tests on every dim's primary key in `models/warehouse/warehouse_schema.yml`. The duplicate-key issue would have been caught by these. Strong DE signal
8. **Final commit + push** — capture all dashboard work, README, screenshots, dbt tests in a clean commit. End-state for v1

### Priority 3 — optional polish (when motivated)

- Refactor surrogate keys to use `dbt_utils.generate_surrogate_key()`
- Add basic GitHub Actions CI workflow (free DE signal)
- Add architecture diagram to README

### Priority 4 — leverage the project

- Add to LinkedIn (Featured section, with screenshot + tagline + repo link)
- Add to resume's Projects section
- Pin the repo on GitHub profile
- Prepare 2–3 interview stories from LEARNINGS — multi-feed key collision is the strongest

## Future projects planned

Tableau, Snowflake, Airflow, Databricks, PySpark,
AWS, Azure, Google Cloud, SQL Server

**Headline plan for project #2:** cloud-native rebuild (Snowflake + Airflow)
with orchestration as the headline feature. Apply carry-forward learnings
from this project's `LEARNINGS.md`: Git from day 1, dbt tests early,
naming conventions documented, source identifiers carried through every
layer, dbt_utils.generate_surrogate_key from the start.
