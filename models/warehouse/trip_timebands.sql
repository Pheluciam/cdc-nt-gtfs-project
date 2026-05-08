{{ config(schema='wh_cdc_nt') }}

WITH trip_bounds AS (
    SELECT
        trip_id,
        MIN(departure_time) AS first_departure
    FROM {{ ref('fact_stop_times') }}
    GROUP BY trip_id
),
normalized AS (
    SELECT
        trip_id,
        first_departure,
        CASE
            WHEN SUBSTRING(first_departure FROM 1 FOR 2)::INT >= 24 THEN
                LPAD((SUBSTRING(first_departure FROM 1 FOR 2)::INT - 24)::TEXT, 2, '0')
                || SUBSTRING(first_departure FROM 3)
            ELSE first_departure
        END AS clock_departure
    FROM trip_bounds
),
trip_to_agency AS (
    SELECT
        t.trip_id,
        a.agency_display_name
    FROM {{ ref('dim_trips') }} t
    JOIN {{ ref('dim_routes') }} r ON t.route_id = r.route_id
    JOIN {{ ref('dim_agency') }} a ON r.agency_key = a.agency_key
),
classified AS (
    SELECT
        n.trip_id,
        n.first_departure,
        CASE
            WHEN clock_departure::TIME BETWEEN TIME '06:00' AND TIME '09:00' THEN 'AM_PEAK'
            WHEN clock_departure::TIME BETWEEN TIME '15:00' AND TIME '18:00' THEN 'PM_PEAK'
            WHEN clock_departure::TIME BETWEEN TIME '09:00' AND TIME '10:00' THEN 'SHOULDER'
            WHEN clock_departure::TIME BETWEEN TIME '18:00' AND TIME '19:00' THEN 'SHOULDER'
            WHEN clock_departure::TIME BETWEEN TIME '05:00' AND TIME '06:00' THEN 'SHOULDER'
            WHEN clock_departure::TIME BETWEEN TIME '14:00' AND TIME '15:00' THEN 'SHOULDER'
            ELSE 'OFF_PEAK'
        END AS timeband,
        ta.agency_display_name
    FROM normalized n
    LEFT JOIN trip_to_agency ta ON n.trip_id = ta.trip_id
)
SELECT
    trip_id,
    first_departure,
    timeband,
    CASE timeband
        WHEN 'AM_PEAK'  THEN 1
        WHEN 'SHOULDER' THEN 2
        WHEN 'PM_PEAK'  THEN 3
        WHEN 'OFF_PEAK' THEN 4
    END AS timeband_sort,
    agency_display_name
FROM classified
