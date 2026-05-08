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
        -- GTFS allows >= 24:00:00 to mean next-day on same service day
        -- Normalise to a 0-23 hour for TIME casting
        CASE
            WHEN SUBSTRING(first_departure FROM 1 FOR 2)::INT >= 24 THEN
                LPAD((SUBSTRING(first_departure FROM 1 FOR 2)::INT - 24)::TEXT, 2, '0')
                || SUBSTRING(first_departure FROM 3)
            ELSE first_departure
        END AS clock_departure
    FROM trip_bounds
)
SELECT
    trip_id,
    first_departure,
    CASE
        WHEN clock_departure::TIME BETWEEN TIME '06:00' AND TIME '09:00' THEN 'AM_PEAK'
        WHEN clock_departure::TIME BETWEEN TIME '15:00' AND TIME '18:00' THEN 'PM_PEAK'
        WHEN clock_departure::TIME BETWEEN TIME '09:00' AND TIME '10:00' THEN 'SHOULDER'
        WHEN clock_departure::TIME BETWEEN TIME '18:00' AND TIME '19:00' THEN 'SHOULDER'
        WHEN clock_departure::TIME BETWEEN TIME '05:00' AND TIME '06:00' THEN 'SHOULDER'
        WHEN clock_departure::TIME BETWEEN TIME '14:00' AND TIME '15:00' THEN 'SHOULDER'
        ELSE 'OFF_PEAK'
    END AS timeband
FROM normalized