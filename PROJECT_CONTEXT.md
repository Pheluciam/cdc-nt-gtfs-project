# CDC NT Transport Project — Session Context

> Last updated: 2026-05-07

## Project overview

- Data Engineering portfolio project for job interviews
- Source data: CDC NT Darwin and Alice Springs GTFS-S (static)
- Stack: Python ingestion → dbt → PostgreSQL → Power BI
- Database: CDC_NT | Warehouse schema: wh_cdc_nt
- Tools: VS Code, pgAdmin 4, dbt, Power BI Desktop
- dbt project path: C:\dbt\cdc_nt_gtfs
- Teaching preferences: see `TEACHING_PREFERENCES.md` for how Claude should work with me

## Working habits — standing reminders

> Claude: surface these at the start of each session and prompt me when relevant.

- **Git: commit regularly.** After every meaningful change (a fix, a new
  model, a working visual), do a `git add` + `git commit` with a clear
  message. Don't let work pile up uncommitted.
- **Push to GitHub at the end of each session** so the remote repo reflects
  the latest progress (also acts as a backup).
- **Pull at the start of each session** before making changes, in case
  anything was committed elsewhere (e.g., from another machine).
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

## Surrogate key convention (added 2026-05-07)

Both source feeds (Darwin and Alice Springs) reuse the same numeric IDs
for different real-world entities, causing duplicate keys when combined.
Resolution: composite surrogate keys built as `feed_id || '_' || natural_id`.

Models updated:

- dim_stops: added `stop_key` (e.g. `darwin_101`, `alice_springs_101`)
- dim_agency: added `agency_key`
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

## Next steps

### First priority — Git setup (do this before any further work)

Project is not currently version controlled. Plan for next session:

1. `git init` in `C:\dbt\cdc_nt_gtfs`
2. Review `.gitignore` (already exists from dbt starter — confirm it excludes
   `dbt_venv/`, `venv_ingestion/`, `target/`, `logs/`, `dbt_packages/`, any
   credentials)
3. First commit covering everything to date with a meaningful message
   (e.g. "Initial commit: GTFS ingestion, dbt warehouse models, Power BI
   star schema with multi-feed surrogate keys")
4. Create GitHub repo (public, for portfolio visibility)
5. Connect local repo to GitHub remote and push
6. Write/expand `README.md` explaining: project goal, stack, data sources,
   how to run, key design decisions (e.g., the surrogate key approach)
7. Going forward: commit after every meaningful change, push regularly

Honesty framing for hiring managers: this was the first project, so version
control was introduced mid-project as a learning step. The pattern matters
more than retroactive history.

### Second priority — start building dashboard visuals

Decide on dashboard structure first, then build one page at a time.

Suggested page structure (pick what feels right):

1. **Overview / KPIs page**
   - Card visuals: total routes, trips, stops, agencies, service days
   - Map of stops (lat/lon already in dim_stops)
   - Agency split (Darwin vs Alice Springs)

2. **Routes page**
   - Trip counts per route (table or bar chart)
   - Most-served vs least-served routes
   - Service calendar per route (use route_service_days summary table)

3. **Stops page**
   - Busiest stops (use stop_activity_summary)
   - Stop locations on a map
   - Trip pass-through counts

4. **Service patterns page**
   - Trips by day-of-week
   - Trips by time-of-day band (use trip_timebands)
   - Weekday vs weekend service comparison

5. **Comparison page (optional)**
   - Darwin vs Alice Springs side-by-side metrics

Once structure is chosen, work one page at a time, verify after each.

## Future projects planned

Tableau, Snowflake, Airflow, Databricks, PySpark,
AWS, Azure, Google Cloud, SQL Server
