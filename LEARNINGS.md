# LEARNINGS.md — CDC NT Transport Project

> A running journal of what I'm learning on this project. First entry: 2026-05-07.

This is my first data engineering project, and I'm using it to build practical
experience with dbt and Power BI — both tools I haven't used as much as I'd
like. The point of this document isn't to look polished. It's to capture the
real moments where something clicked, broke, or made me rethink an assumption,
so I can refer back to it in interviews and on future projects.

---

## Project summary

End-to-end data engineering portfolio project using public GTFS-Static feeds
from the Northern Territory's two transit agencies (Darwin and Alice Springs).
The pipeline is Python ingestion → PostgreSQL → dbt transformations → Power BI.
Goal: a working star schema and a small dashboard to demonstrate the full stack
is wired up and producing usable analytics.

---

## Technical learnings

### dbt

- **The staging → intermediate → warehouse pattern.** Source data lands raw,
  staging cleans column names and types, intermediate models do business logic
  joins, warehouse models produce facts and dims ready for BI. Keeping these
  layers separate makes each model easier to debug than one giant query.
- \*\*`{{ ref('model_name') }}` builds the dependency graph. Using `ref()`
  instead of hardcoded table names is what lets dbt know what to rebuild and
  in what order. Hard-coded table names break this.
- **`dbt run --select model_name`** rebuilds one specific model. Useful when
  iterating — much faster than rebuilding the whole project. Once tripped up
  by running the wrong model name (ran `dim_agency` when I meant `dim_stops`)
  and spent a while wondering why my fix wasn't taking effect. The dbt log
  output is gospel — read it before assuming the run did what you intended.
- Views vs tables. dbt models default to views unless configured
  otherwise. A view is a saved query — fast to update, slow to read. A table
  materialises the data — slower to build, faster to query. For BI workloads,
  warehouse-layer fact and dim tables generally make sense as tables. Still
  learning when each makes sense.
- **`dbt run` parses, doesn't execute (for views).** A clean `dbt run`
  only proves the SQL *parses*. Bugs that only surface at query time —
  type casts, range errors, missing columns in upstream views — won't show
  up until something actually reads from the view (Power BI, a downstream
  model, a manual `SELECT`). Hit this with a `::TIME` cast on a GTFS
  `24:26:00` value: dbt was happy, Power BI was not. Materialising as a
  table forces execution at build time, which would have caught it earlier.
- **`dbt run --select model+` rebuilds a model AND everything downstream.**
  The `+` suffix tells dbt to walk the dependency graph forward. Useful
  when you fix a model and need every dependent model regenerated in one
  command. (`+model` rebuilds upstream dependencies; `+model+` does both.)

### Power BI

- Cardinality is enforced at relationship-creation time, not runtime Power
  BI refuses to create a many-to-one relationship if the "one" side has
  duplicate keys. My initial blocker was exactly this: `dim_stops.stop_id` had
  75 duplicates (from two GTFS feeds reusing the same numeric IDs), so the
  relationship to `fact_stop_times` couldn't be created. I'd previously thought
  Power BI would just warn about this and let it slide — it doesn't.
- ** Auto-detected relationships are dangerous.** When you refresh data, Power
  BI looks for matching column names across tables and creates relationships
  for them. Helpful in obvious cases, harmful when it picks wrong: it
  auto-created a `fact_trips → fact_route_summary` relationship on `route_id`
  (fact-to-fact, doesn't belong in a star schema) and a few `feed_id`
  relationships I didn't want. Always sanity-check **Manage Relationships**
  after a refresh.
- **Ambiguous paths.** If two tables already have a relationship path between
  them (direct or indirect), Power BI refuses to add a second one — even if
  the second is the "real" one. Have to delete the wrong one first.
- **Filter direction matters.** Single-direction (Many-to-One) means the dim
  filters the fact, not vice versa. Bi-directional is rarely needed and tends
  to cause weird filter side effects. Default to single.
- **Model view is purely visual.** Layout has no effect on behaviour. I prefer
  dims along the top, facts along the bottom — relationship arrows all point
  upward, easy to scan.
- **Table vs Matrix visuals.** In newer Power BI versions, dragging fields
  sometimes defaults to a Matrix, which has different field wells (Rows /
  Columns / Values) and different summarisation behaviour. Switch to Table
  visual for plain tabular output.
- **Transaction-cascade error display.** When Power BI's "Get Data" loads
  multiple tables in one batch, all tables go through PostgreSQL in a
  single transaction. If *one* table's query errors out, the whole
  transaction rolls back and Power BI shows "failed" against *every*
  table in that batch — even tables that would have loaded fine on their
  own. The error message includes the phrase *"another operation in the
  transaction failed"* — that's the giveaway. Don't waste time
  troubleshooting tables that aren't the actual problem; find the one
  real failure (the underlying error usually points at it) and fix that.

### PostgreSQL

- **Postgres is strict about types.** `WHERE stop_id = 101` failed with
  `operator does not exist: text = integer` because `stop_id` is stored as
  text. Adding quotes (`= '101'`) fixed it. Lesson: when GTFS or any external
  source uses string IDs (which is the GTFS spec), Postgres won't silently
  cast.
- **`information_schema`** is your friend for inspecting columns without
  running the model. `SELECT column_name FROM information_schema.columns WHERE
table_schema = 'X' AND table_name = 'Y'` answers "is this column actually
  there?" — useful when something downstream is breaking.
- **`INTERVAL` vs `TIME` for GTFS extended hours.** PostgreSQL's `TIME`
  type only accepts hours 0-23, so any cast like `'24:26:00'::TIME` errors
  out. `INTERVAL` accepts the same string and treats it as 24 hours
  26 minutes — exactly what GTFS intends for late-night trips that span
  midnight. When doing time arithmetic on data that might contain GTFS
  extended hours (duration calculations, time-band classification),
  default to `::INTERVAL` rather than `::TIME`. INTERVAL also supports
  arithmetic (`a - b` returns an interval) and `EXTRACT(EPOCH FROM ...)`
  works the same way for both. Same syntax, more permissive type.

### Star schema fundamentals (reinforced)

- Knew this from BI work, but it crystallised this session: dim tables are
  **lookup tables**, fact tables are **event logs**. dim_stops should have one
  row per real-world stop. fact_stop_times should have many rows per stop —
  one per visit. If a fact "dedupes" you've broken something, not fixed it.
- The "one" side of a relationship needs unique keys. The "many" side doesn't.
  Once that lens clicks, errors about cardinality become much easier to
  diagnose.

### Working across the stack

- **dbt → Postgres → Power BI sync.** Three layers, each with their own state.
  When something doesn't behave: (1) `dbt run` the relevant models, (2) verify
  the data in Postgres directly via pgAdmin, (3) refresh Power BI. Skip any
  step and you'll spend an hour chasing a problem that no longer exists.
- **Audit before fixing.** When I hit one duplicate (`stop_id = 86`) my
  instinct was to fix that one model. Better instinct: audit _every_ dim
  table for duplicate keys first. Found that two dims had the issue, both
  with the same root cause. One round of fixes vs whack-a-mole.

---

## Mistakes & diagnoses

These are the moments worth talking about in interviews.

### Multi-feed ID collision

**Symptom:** Power BI refused to create the `fact_stop_times → dim_stops`
relationship. `stop_id = 86` was duplicated.

**Diagnosis:** Pulled all rows for the duplicated `stop_id`s and looked at
them side-by-side. Same `stop_id`, completely different stops in different
cities (Darwin lat -12, Alice Springs lat -23). Confirmed: Darwin and Alice
Springs each numbered their stops from scratch starting at 1, and the
ingestion combined both feeds without distinguishing them.

**Fix:** Composite surrogate keys built as `feed_id || '_' || natural_id`.
`darwin_101` and `alice_springs_101` are now different keys. Applied the same
pattern to `dim_agency`, `fact_stop_times`, and `dim_routes`.

**What this taught me:** when integrating multiple sources of similar data,
the very first design question should be "are the IDs unique across sources?"
If not, you need a feed/source identifier baked into the key from day one.
Adding it later (like I did) means rippling changes through every downstream
model — much more painful.

### Wrong dbt model rebuilt

**Symptom:** Ran `dbt run --select dim_agency` when I meant `dim_stops`. The
audit query then continued to show duplicates, which was confusing because I
"thought" I'd fixed it.

**Diagnosis:** Re-read the dbt run output. The log clearly showed `dim_agency`,
not `dim_stops`. I'd skim-read the success message and missed the model name.

**What this taught me:** the dbt log is the source of truth for what was
rebuilt. Read it carefully, especially when something downstream behaves
unexpectedly.

### Postgres type mismatch

**Symptom:** `SELECT * FROM dim_stops WHERE stop_id = 101` errored with
`operator does not exist: text = integer`.

**Diagnosis:** `stop_id` is stored as text. Postgres won't auto-cast.

**Fix:** `WHERE stop_id = '101'`.

**What this taught me:** GTFS spec uses string IDs. Don't assume numeric
just because the data looks numeric.

### Power BI auto-detected relationships

**Symptom:** After refreshing Power BI post-dbt-rebuild, the relationship
list contained several relationships I hadn't created — including a
`fact_trips → fact_route_summary` (fact-to-fact, wrong) and a few `feed_id`
ones (matched on column name, conceptually meaningless).

**Diagnosis:** Power BI's autodetect saw matching column names and created
relationships for them. Refresh triggered this.

**Fix:** Reviewed the full relationship list, deleted incorrect ones,
manually created the right ones.

**What this taught me:** every refresh should be followed by a quick
**Manage Relationships** review. Autodetect is a starting hint, not a
finished decision.

### GTFS extended times (24:00+) broke `trip_timebands` at query time

**Symptom:** Power BI's "Get Data" against `trip_timebands` failed with:

> `PostgreSQL: 22008: date/time field value out of range: "24:26:00"`

`dbt run` had completed successfully with no errors. The break only
appeared when Power BI tried to query the view.

**Diagnosis:** Two stacked issues.

First, the GTFS spec allows departure times like `24:26:00` or `25:30:00`
to mean *"next-day clock time, but still part of today's service day."*
This is intentional — keeps a late-night trip that crosses midnight inside
the same service-day grouping rather than splitting it across two calendar
dates. PostgreSQL's `TIME` type only accepts 0–23 hours, so any cast like
`first_departure::TIME` throws a range error on these values.

Second, my `trip_timebands.sql` was materialised as a view (dbt default).
`dbt run` only validates that the SQL parses — it doesn't execute it.
The `::TIME` cast only failed when Power BI actually queried the view.

**Fix:** Normalise GTFS extended hours back to 0–23 range before casting:

```sql
CASE
    WHEN SUBSTRING(first_departure FROM 1 FOR 2)::INT >= 24 THEN
        LPAD((SUBSTRING(first_departure FROM 1 FOR 2)::INT - 24)::TEXT, 2, '0')
        || SUBSTRING(first_departure FROM 3)
    ELSE first_departure
END AS clock_departure
```

Then `clock_departure::TIME` works for every row, and the time-band
classification still makes sense (a `24:26` trip is treated as a `00:26`
trip for clock-time bucketing — which is the right answer).

**What this taught me:**

- A green `dbt run` log doesn't equal "tested." For view-materialised
  models, only parsing has been validated. Bugs surface when downstream
  consumers query the view. Worth knowing for debugging — when something
  downstream breaks, don't trust the dbt log alone, run a `SELECT *` from
  the view manually before assuming dbt is fine.
- Real-world data spec quirks are exactly the kind of thing DE work runs
  into. The GTFS extended-hours convention is documented in the spec, but
  it's the kind of detail you only notice when it breaks something. Worth
  reading source data specs carefully — would have saved time here.

### Misleading column name hid a 1000× unit error in trip_kpis

**Symptom:** `avg_speed_kmh` from `trip_kpis` returned values like 0.02,
0.01, 0.009 km/h — three orders of magnitude too low for buses, which
should sit in the 15–40 km/h range.

**Diagnosis:** The model had a CTE column named `total_distance_m` (with
the `_m` suffix suggesting metres). The downstream calculation divided
by 1000.0 to "convert metres to km." But the actual data in
`shape_dist_traveled` from this GTFS feed was already in **kilometres**.
So the calculation was going from km → "km / 1000" → labelling the
result as km. Speed was therefore 1000× too small.

**Fix:**

1. Renamed the CTE column from `total_distance_m` to `total_distance_km`
   to reflect the actual unit
2. Removed every `/1000.0` division — the data is already in the unit we
   want
3. Verified after rebuild: bus speeds returned to the realistic 15–40
   km/h range

**What this taught me:**

- **Column names are documentation, not labels.** A misleadingly-named
  column quietly propagates errors through every downstream calculation.
  No one in the chain questioned what `total_distance_m` actually
  contained because the name said "metres."
- **GTFS `shape_dist_traveled` units are agency-specific.** The spec
  doesn't enforce metres or km — different feeds use different units,
  some leave it null. When ingesting GTFS, the unit is *always* worth
  verifying against the feed's `feed_info.txt` or by sanity-checking a
  known route's real-world length against the column's value.
- When derived metrics look wrong, **trace the units** before assuming
  the formula is wrong. The formula here was correct; the input
  assumptions were wrong.

### Power BI transaction-cascade displayed every loaded table as failed

**Symptom:** Tried to "Get Data" five new summary tables. Got an error
referencing PostgreSQL `22008: date/time field value out of range`.
Then opened Manage Tables and saw *all 15 tables* (10 existing + 5 new)
showing as failed — including tables I hadn't touched.

**Diagnosis:** Power BI batches table loads into a single PostgreSQL
transaction. When one query failed (a `::TIME` cast on a GTFS extended
hour value, in `trip_kpis`), the transaction rolled back, and every
table in the batch was marked failed by Power BI — not just the one
that actually broke.

The original error message included the phrase *"The current operation
was cancelled because another operation in the transaction failed"* —
that's the cascade signal.

**Fix:** Found the real failing model (`trip_kpis` doing `::TIME` casts
that hit GTFS extended hours), patched it (`::TIME` → `::INTERVAL`),
rebuilt downstream models, and re-ran Power BI Get Data. All 15 tables
loaded cleanly.

**What this taught me:**

- Don't waste time investigating every "failed" table when Power BI
  reports a batch failure. Look for the *root cause* error in the
  transaction; the rest are symptoms.
- The "another operation failed" phrasing is the diagnostic flag. When
  you see it, the failure is upstream of what you think you're looking at.

---

## Design decisions

### Why composite surrogate keys (`feed_id || '_' || natural_id`) over alternatives

**Considered:**

1. **Composite natural key** — keep `(feed_id, natural_id)` as the primary
   key, no surrogate. Power BI doesn't love composite keys for relationships
   (you can do it, but it's clunky), so ruled out.
2. **Numeric surrogate key** — auto-incrementing integer. Cleanest in theory,
   but loses the readable "this is darwin's stop 101" debugging benefit and
   requires a separate mapping table.
3. **`feed_id || '_' || natural_id`** — chosen. Readable (`darwin_101`),
   stable (regenerates the same way every dbt run), unique, easy to filter on
   in Power BI for debugging.

**Trade-off accepted:** key length grows with feed name length. Not a
performance issue at this scale; could become one if scaled to dozens of
feeds.

### Single direction filter on all relationships

Default Many-to-One with single-direction filter for everything. Avoids
weird filter propagation issues that bi-directional relationships can cause
in DAX measures. Easy to revisit per-relationship if a specific need arises.

### Display-name logic: dbt vs Power BI relationship

Hit this twice on this project. Both times needed clean human-readable
labels (e.g., "Darwin" / "Alice Springs") instead of internal feed_id
values. Two viable options:

- **Option A — add a display column in dbt** (e.g., `agency_display_name`
  via a `CASE WHEN feed_id = 'darwin' THEN 'Darwin' ...` in the warehouse
  model). Display logic lives in the warehouse and is visible to anyone
  querying the database.
- **Option B — add a Power BI relationship on a shared key** (e.g.,
  `dim_stops → dim_agency` on `feed_id`) and then use `dim_agency`'s
  existing display name via the relationship. Display logic lives in the
  `.pbix` file.

Picked **A** for `dim_agency` (cleaner, more DE-idiomatic). Picked **B**
for `dim_stops` because it was faster and the project was already
pressuring time. Both work, both are defensible.

**What I'd do next time:** default to A every time. Display logic in the
warehouse is visible in code review, version-controlled, and works for
any consumer (Tableau, ad-hoc SQL, future dashboards), not just this
specific Power BI file. The speed benefit of B is small; the
hidden-in-binary cost is not. Consistency matters more than the speed
saved on any single chart.

---

## Pipeline orchestration (and why this v1 is manual)

This project's pipeline is intentionally manual: I run Python ingestion,
then `dbt run`, then refresh Power BI by hand. For a v1 portfolio piece,
that's a deliberate scope decision — the goal here was to wire up the full
stack end-to-end and prove every link works, not to automate operation.

In a real production setting, manual operation isn't acceptable. The
natural next step is orchestration via Airflow (or similar tool — Dagster,
Prefect, or even cron with a shell script for a simpler version). The DAG
would look like:

1. Download latest GTFS feeds (Python task)
2. Validate files exist and are well-formed (data quality check)
3. Load to Postgres staging (Python ingestion)
4. `dbt build` — runs models and tests in one step
5. Refresh Power BI dataset via REST API
6. Notify on success / failure (Slack or email)

Schedule: monthly, since GTFS feeds typically publish a refresh each month
with timetable updates.

**Why I parked this for project #2 rather than adding it here:**

- v1 was about getting the pipeline working end-to-end first. Orchestrating
  something half-built would have been premature
- Airflow setup adds substantial complexity (scheduler, web UI, often
  Docker). Worth introducing as the headline feature of the next project
  rather than a footnote in this one
- For interview purposes, being able to articulate the orchestration
  design — which I can — captures most of the value. Implementation comes
  in project #2

The cloud-native rebuild (planned project #2: Snowflake + Airflow) is the
natural place for this to land as the headline feature.

---

## What I'd do differently next time

- **Set up Git from day 1.** Should not have to retroactively introduce
  version control. First commit before writing any code, public GitHub repo
  early, regular commits as habit. (Doing this on this project now, but
  marked as a learning so I don't repeat the mistake.)
- **Propagate `feed_id` everywhere from staging onward.** This project's
  ingestion already added `feed_id` to source rows, but warehouse models
  weren't carrying it through consistently. If `feed_id` had been a
  first-class citizen from the start, the duplicate-key issue would have
  surfaced immediately at staging, not in Power BI.
- **Audit dim uniqueness before attempting Power BI relationships.** Run a
  duplicate-check on every dim's primary key as part of the dbt build
  pipeline (likely as a dbt test). Catches issues at the warehouse layer
  before they ever reach BI.
- **Establish naming conventions early.** Mixed convention (some dims have
  `*_key`, some don't) made cleanup harder than it needed to be. Decide once,
  apply everywhere.
- **Put units in column names AND verify they match the data.**
  `total_distance_m` quietly contained km-valued data in this project,
  hiding a 1000× error in every speed calculation. Either: enforce units
  at ingestion (convert all distances to a single canonical unit before
  storing), or be paranoid about audits when receiving distance/time/money
  columns from external sources.
- **Default to `INTERVAL` over `TIME` for any time arithmetic on data that
  may include GTFS-style extended hours.** It's a free upgrade — same
  syntax, more permissive, no edge-case errors on midnight-crossing data.
  Reach for `::TIME` only when you specifically want clock-time bucketing
  (e.g., classifying into peak/shoulder/off-peak time bands), and even
  then normalise extended hours first.
- **Keep display logic in dbt, not Power BI.** Doing the same display-name
  work in two layers (`agency_display_name` via dbt + `dim_stops → dim_agency`
  via Power BI relationship) was a missed consistency opportunity. Consumer
  tools should read clean labels; the warehouse is where labels are defined.

---

## Open questions / things still shaky

- **Jinja in dbt.** I can read it but writing macros from scratch is still
  uncomfortable.
- **dbt tests.** Aware they exist (`unique`, `not_null`, etc.) but haven't
  used them yet. The duplicate-key issue would have been caught instantly by
  a `unique` test on `dim_stops.stop_key` — strong motivation to learn.
- **`dbt_utils.generate_surrogate_key()`** — the more idiomatic dbt way to
  build surrogate keys (uses `dbt_utils` package). I went with `||`
  concatenation manually. Want to refactor to the package version once I
  understand it better.
- **dbt incremental models.** Right now everything rebuilds from scratch.
  Fine for static GTFS, but I'd need incremental for any real-world streaming
  or growing dataset.
- **Power BI DAX measures.** I'm using implicit measures (drag a column,
  summarise to count). Real Power BI work uses explicit DAX measures with
  proper formatting. Need to learn that next.
- **Git workflow at any depth.** Branching, merging, pull requests, conflict
  resolution — all unfamiliar territory. Picking these up incidentally as I
  work, rather than dedicated study.

---

## Carry-forward to the next project

Things I want to do _from day one_ on the next project:

1. Git initialised and pushed to GitHub before writing any code.
2. `LEARNINGS.md` and `README.md` created day one, updated as I go.
3. dbt tests on every dim's primary key.
4. Source identifiers carried through every layer if combining multiple
   sources.
5. Naming conventions decided and documented before building models.
6. Use `dbt_utils.generate_surrogate_key` instead of manual concatenation.
7. **Orchestration from the start.** Airflow (or equivalent) DAG that runs
   the pipeline end-to-end on a schedule, with proper failure handling and
   notifications. Not a v2 thought — designed in from day one.
8. **Verify column units against actual data on ingestion.** Don't trust
   column-name suffixes (`_m`, `_km`, `_secs`). Sanity-check a known
   value against reality (or against the source's documentation) before
   assuming the unit. Better still: convert everything to canonical
   units at staging and never have ambiguity downstream.
9. **Default to `::INTERVAL` for time math.** Avoids the GTFS extended-hours
   trap from day one. Use `::TIME` only when clock-time bucketing is
   specifically what you want, and normalise GTFS hours first.
10. **All display logic in dbt, not BI tools.** Pretty labels, business-rule
    case statements, reformatted strings — all belong in the warehouse so
    every consumer sees the same clean values. BI tools render; they don't
    define.
