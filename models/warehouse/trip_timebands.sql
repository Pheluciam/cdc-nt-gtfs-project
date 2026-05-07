{{ config(schema='wh_cdc_nt') }}

WITH trip_bounds AS (
    SELECT
        trip_id,
        MIN(arrival_time) AS first_arrival,
        MIN(departure_time) AS first_departure
    FROM {{ ref('fact_stop_times') }}
    GROUP BY trip_id
),
classified AS (
    SELECT
        tb.trip_id,
        tb.first_departure,
        CASE
            WHEN tb.first_departure::TIME BETWEEN TIME '06:00' AND TIME '09:00' THEN 'AM_PEAK'
            WHEN tb.first_departure::TIME BETWEEN TIME '15:00' AND TIME '18:00' THEN 'PM_PEAK'
            WHEN tb.first_departure::TIME BETWEEN TIME '09:00' AND TIME '10:00' THEN 'SHOULDER'
            WHEN tb.first_departure::TIME BETWEEN TIME '18:00' AND TIME '19:00' THEN 'SHOULDER'
            WHEN tb.first_departure::TIME BETWEEN TIME '05:00' AND TIME '06:00' THEN 'SHOULDER'
            WHEN tb.first_departure::TIME BETWEEN TIME '14:00' AND TIME '15:00' THEN 'SHOULDER'
            ELSE 'OFF_PEAK'
        END AS timeband
    FROM trip_bounds tb
)
SELECT *
FROM classified
