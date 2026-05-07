-- Duplicate-key audit across wh_cdc_nt dim tables
-- Each row = one dim table's check
-- duplicates > 0  ->  blocks Power BI "one" side

SELECT
    'dim_agency'                          AS table_name,
    'agency_id'                           AS key_col,
    COUNT(*)                              AS total_rows,
    COUNT(DISTINCT agency_id)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT agency_id)  AS duplicates
FROM wh_cdc_nt.dim_agency

UNION ALL

SELECT
    'dim_calendar'                         AS table_name,
    'service_id'                           AS key_col,
    COUNT(*)                               AS total_rows,
    COUNT(DISTINCT service_id)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT service_id)  AS duplicates
FROM wh_cdc_nt.dim_calendar

UNION ALL

SELECT
    'dim_date'                       AS table_name,
    'date'                           AS key_col,
    COUNT(*)                         AS total_rows,
    COUNT(DISTINCT date)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT date)  AS duplicates
FROM wh_cdc_nt.dim_date

UNION ALL

SELECT
    'dim_routes'                         AS table_name,
    'route_id'                           AS key_col,
    COUNT(*)                             AS total_rows,
    COUNT(DISTINCT route_id)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT route_id)  AS duplicates
FROM wh_cdc_nt.dim_routes

UNION ALL

SELECT
    'dim_service_calendar'                 AS table_name,
    'service_id'                           AS key_col,
    COUNT(*)                               AS total_rows,
    COUNT(DISTINCT service_id)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT service_id)  AS duplicates
FROM wh_cdc_nt.dim_service_calendar

UNION ALL

SELECT
    'dim_stops'                         AS table_name,
    'stop_key'                          AS key_col,
    COUNT(*)                            AS total_rows,
    COUNT(DISTINCT stop_id)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT stop_id)  AS duplicates
FROM wh_cdc_nt.dim_stops

UNION ALL

SELECT
    'dim_trips'                         AS table_name,
    'trip_id'                           AS key_col,
    COUNT(*)                            AS total_rows,
    COUNT(DISTINCT trip_id)             AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT trip_id)  AS duplicates
FROM wh_cdc_nt.dim_trips

ORDER BY duplicates DESC, table_name;

SELECT * FROM wh_cdc_nt.dim_agency LIMIT 100;
