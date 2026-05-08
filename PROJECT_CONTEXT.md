# CDC NT Transport Project — Session Context

> Last updated: 2026-05-08 (end of session 4)

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
- dim_date: added `day_of_week_num` (ISO weekday Mon=1...Sun=7) for chronological sort; TRIM applied to day_of_week to remove TO_CHAR padding
- trip_timebands: added `agency_display_name` (joined via dim_trips → dim_routes → dim_agency) and `timeband_sort` column

Natural keys (route_id, trip_id, service_id, date, agency_id, stop_id)
remain in tables for reference but should not be used for relationships
where a surrogate key exists.

## Power BI — relationships completed

Active (17):

Core star (10):

- fact_trips → dim_calendar on service_id
- fact_trips → dim_trips on trip_id
- fact_trips → dim_routes on route_id
- fact_service_days → dim_calendar on service_id
- fact_service_days → dim_date on date
- fact_route_summary → dim_routes on route_id
- fact_stop_times → dim_trips on trip_id
- fact_stop_times → dim_stops on stop_key
- dim_routes → dim_agency on agency_key
- dim_stops → dim_agency on feed_id (added for clean labels in Stops per Agency chart)

Summary tables (added session 3, 7):

- route_kpis → dim_routes on route_id
- route_service_days → dim_routes on route_id
- trip_kpis → dim_routes on route_id
- trip_kpis → dim_calendar on service_id
- trip_kpis → dim_trips on trip_id
- trip_kpis → dim_date on date (manually added)
- trip_timebands → dim_trips on trip_id (changed from 1:1 to many-to-1 for consistency)

Inactive (1):

- dim_trips → dim_calendar on service_id

Star schema verified end-to-end via functional test (agency × route ×
trip count, total = 2070, correctly distributed across both feeds).

## Git status

✅ Repo on GitHub: https://github.com/Pheluciam/cdc-nt-gtfs-project

End of session 2 — pushed commit covering: dim_agency display name,
LEARNINGS.md expansion, Power BI Overview page work.

End of session 3 — pushed: trip_timebands GTFS extended-hours fix
(SUBSTRING/LPAD normalisation), trip_kpis fix (`::TIME` → `::INTERVAL`,
column rename `total_distance_m` → `total_distance_km`, removed bogus /1000
divisions), Power BI Network Coverage page complete, summary tables loaded
into Power BI with 7 new relationships, LEARNINGS.md expanded.

End of session 4 — commit pending. Covers: dim_date day_of_week_num + TRIM,
trip_timebands restructured to derive timeband_sort from timeband (1:1 safe)
and added agency_display_name via JOIN, Power BI Service Operations page
complete (clustered bar charts with agency split), Multi-Feed Comparison
page started with transposed matrix using "Show values on rows" toggle,
DAX `Agency Sort` calculated column added in Power BI for column sort.

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
- ✅ **Page 2 — Network Coverage** structurally complete
  - Title + subtitle
  - Map visual: dim_stops by lat/lon, coloured by feed_id (two clusters render correctly)
  - Routes per Agency bar (Darwin 70-something, Alice Springs ~10)
  - Stops per Agency bar (Darwin 669, Alice Springs 99, total 768)
- ✅ **Page 3 — Service Operations** structurally complete
  - Title + subtitle
  - Trips by Time Band — clustered bar with agency split (Darwin/Alice Springs side-by-side per band)
  - Service Trips by Day of Week — clustered bar with agency split, sorted Mon→Sun via day_of_week_num
  - Note: time band chronological sort attempted but deferred — Power BI Sort by column 1:1 issue we couldn't isolate. Sort is by count-descending instead. Acceptable for v1
- 🔧 **Page 4 — Multi-Feed Comparison** in progress
  - Title + subtitle done
  - Transposed matrix showing 4 metrics × 2 agencies (Routes/Trips/Stops/Stop visits, Darwin/Alice Springs as columns)
  - Used Power BI's "Switch values to rows" toggle to flip the matrix orientation
  - DAX `Agency Sort` calculated column on `wh_cdc_nt dim_agency` to put Darwin first (1) before Alice Springs (2)
  - Sort by column applied to `agency_display_name` → `Agency Sort`
  - Page feels sparse — needs one more visual

## Next steps — pick up here next session

### Priority 1 — finish the dashboard

Pages 2 and 3 are structurally complete. Remaining:

1. **Page 1 — Overview**: feels sparse (5 KPI cards + 1 bar chart). Add one more visual for variety. Options to consider (no need to do them all):
   - **Multi-row card** showing additional headline numbers (date range, avg trip distance, total km of service, etc.)
   - **Treemap** of trip counts per agency (different from existing bar chart)
   - **Top 10 routes by trip count** as a horizontal bar chart
   - **Hour of day distribution** of trip start times — would need new column in trip_timebands or trip_kpis (`EXTRACT(HOUR FROM departure_time)` or similar). Genuinely different visual angle. Line/area chart works well

2. **Page 4 — Multi-Feed Comparison**: matrix done, needs second visual that adds different angle. Options Phil flagged as interesting:
   - **Average trip distance** by agency — uses `trip_kpis.kms` with AVERAGE aggregation, clustered bar
   - **Average trip speed** by agency — uses `trip_kpis.avg_speed_kmh`, similar
   - **Hour of day comparison** — line chart with two series (Darwin, Alice Springs) showing trip start times. Strongest "different angle" option. Same dbt addition needed as Overview's hour-of-day idea
   - **Decomposition tree** — Power BI's analytical visual, breaks down trips → agency → route. Genuinely different, signals analytical sophistication
   - **Scatter plot** — routes plotted by avg_speed × avg_distance, coloured by agency. Two routes could share a quadrant or differ wildly

   Avoid: another donut/stacked bar (already used elsewhere).

3. **Polish pass** — fonts, alignment, colours consistent across all 4 pages, page tab order correct.

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
