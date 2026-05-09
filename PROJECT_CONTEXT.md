# CDC NT Transport Project — Session Context

> **STATUS: v1 SHIPPED** (2026-05-09)
>
> Project complete. Commit `4a5ebe9` is the v1 ship commit on `main`.
> See `NEXT_PROJECT.md` for project #2 planning.

---

## Project overview

- Data Engineering portfolio project
- Source data: CDC NT Darwin and Alice Springs GTFS-S (static)
- Stack: Python ingestion → dbt → PostgreSQL → Power BI
- Database: CDC_NT | Warehouse schema: wh_cdc_nt
- Tools: VS Code, pgAdmin 4, dbt, Power BI Desktop
- dbt project path: C:\dbt\cdc_nt_gtfs
- GitHub repo: https://github.com/Pheluciam/cdc-nt-gtfs-project (public)
- Teaching preferences: see `TEACHING_PREFERENCES.md` for how Claude should work with me

---

## v1 ship summary

- ✅ End-to-end pipeline working: Python ingestion → PostgreSQL → dbt (36 models) → Power BI (4 pages)
- ✅ Multi-feed surrogate key engineering (handled the Darwin/Alice Springs ID collision)
- ✅ GTFS extended-hours fix (`::INTERVAL` over `::TIME` for time math)
- ✅ Star schema with deliberate snowflakes (`dim_routes → dim_agency`, `dim_stops → dim_agency`)
- ✅ 28 dbt tests passing (`unique` + `not_null` on all dim primary keys, plus relationship tests)
- ✅ 4-page Power BI dashboard with consistent theme, screenshots embedded in README
- ✅ Mermaid architecture diagram in README
- ✅ Git repo public, clean commit history
- ✅ LEARNINGS.md, NEXT_PROJECT.md, README.md all in place

**v1 deliberate scope decisions** (documented as carry-forward to project #2):

- Manual pipeline (no orchestration) — Airflow is the headline feature for project #2
- Local PostgreSQL (no cloud warehouse) — cloud is the v2 platform
- Hand-rolled surrogate keys (`||` concatenation rather than `dbt_utils.generate_surrogate_key`)
- No CI/CD pipeline (deliberate v2 addition)
- No incremental models (whole pipeline rebuilds each run — fine for static data)

---

## Working habits — standing reminders

> Carry these forward to project #2 — same habits, fresh repo.

- **Pull at the start of each session** — `git pull` before making changes
- **Git: commit regularly.** After every meaningful change (a fix, a new
  model, a working visual), do a `git add` + `git commit` with a clear
  message. Don't let work pile up uncommitted.
- **Push to GitHub at the end of each session** so the remote repo reflects
  the latest progress (also acts as a backup).
- **README stays current.** If a session added a new model, dependency,
  or design decision, update `README.md` before pushing.
- **LEARNINGS.md captures takeaways.** At the end of each session — or whenever
  something clicks, breaks, or surprises me — add an entry to `LEARNINGS.md`
  while it's fresh. Short, honest reflections: what worked, what tripped me
  up, what I'd do differently.
- **Read `LEARNINGS.md` at the start AND end of each session.** Start: re-anchor
  in what I learned previously. End: reinforce what's worth capturing from today.

---

## dbt warehouse models (final state)

Fact tables: `fact_stop_times`, `fact_trips`, `fact_route_summary`,
`fact_service_days`, `fact_stop_sequences`

Dim tables: `dim_agency`, `dim_calendar`, `dim_calendar_dates`, `dim_date`,
`dim_routes`, `dim_service_calendar`, `dim_shapes`, `dim_stops`, `dim_trips`

Summary / mart tables: `route_kpis`, `trip_kpis`, `route_service_days`,
`shape_summary`, `stop_activity_summary`, `trip_timebands`

Surrogate keys added: `stop_key` (dim_stops + fact_stop_times), `agency_key`
(dim_agency + dim_routes), `agency_display_name`, `day_of_week_num`,
`timeband_sort`.

---

## Power BI dashboard — final state

**4 pages, all complete:**

1. ✅ **Overview** — title + pitch, 5 KPI cards (Agencies, Routes, Trips, Stops, Stop Visits), Trips by Agency bar, Routes treemap
2. ✅ **Network Coverage** — title + subtitle, stops map (lat/lon), Routes per Agency donut, Stops per Agency donut
3. ✅ **Service Operations** — title + subtitle, Trips by Time Band clustered bar, Service Trips by Day of Week clustered bar
4. ✅ **Multi-Feed Comparison** — title + subtitle, two side-by-side multi-row cards (Darwin, Alice Springs), Average Kilometres by Agency bar

**Theme:** Frontier. **Colours:** Darwin teal, Alice Springs gold/ochre.

**Power BI relationships:** 17 active + 1 inactive (full list previously documented; star schema verified end-to-end with functional test totalling 2,070 trips correctly distributed).

---

## Git history

Final commit: `4a5ebe9 — v1 SHIP: dbt tests added (28 passing), README + architecture diagram, NEXT_PROJECT updates, LEARNINGS cleanup`

Previous commits (recent first):

- `4a5ebe9` — v1 SHIP
- `9fb2dca` — Add NEXT_PROJECT.md roadmap and session sanity checks
- `088de32` — Session 4: Service Operations + Multi-Feed Comparison pages, dim_date day_of_week_num, trip_timebands restructured for safe 1:1 sort, DAX Agency Sort column, LEARNINGS expanded
- `b33b476` — Session 3: GTFS extended-time fixes, trip_kpis unit correction, Network Coverage page, summary tables loaded, LEARNINGS expanded
- ... (full history visible via `git log --oneline`)

---

## Next steps

**For this project:** none. v1 is shipped. Anything beyond is optional polish (see `NEXT_PROJECT.md` "Things to bring forward" for what would be carried to v2).

**For project #2:** see `NEXT_PROJECT.md` for the full roadmap. Headline plan:
cloud-native rebuild on a supply-chain / demand-planning dataset, with
orchestration via Airflow as the headline feature. MS SQL Server, Databricks,
or Snowflake stack to be decided.

**For ongoing leverage of project #1:**

- Add to resume's Projects section
- Pin the repo on GitHub profile
- Prepare 2–3 interview stories from LEARNINGS

---

## Future projects planned

Tableau, Snowflake, Airflow, Databricks, PySpark,
AWS, Azure, Google Cloud, SQL Server, MS SQL Server.

**Three-project plan** (per `NEXT_PROJECT.md`):

| Project | Headline | Status |
|---|---|---|
| **#1 — CDC NT Transport** | End-to-end pipeline | ✅ SHIPPED |
| **#2 — Demand Planning** | Production-grade pipeline (orchestration, cloud, marts, partitioning) | Planned — see NEXT_PROJECT.md |
| **#3 — TBD** | Depends on what feels weakest after #2 | TBD |
