{{ config(schema='wh_cdc_nt') }}

WITH trips AS (
    SELECT
        trip_id,
        route_id,
        service_id,
        trip_headsign,
        direction_id,
        shape_id
    FROM {{ ref('stg_trips') }}
),

stop_times AS (
    SELECT
        trip_id,
        MIN(arrival_time::INTERVAL) AS start_time,
        MAX(departure_time::INTERVAL) AS end_time,
        COUNT(*) AS stop_count
    FROM {{ ref('fact_stop_times') }}
    GROUP BY trip_id
)

SELECT
    t.trip_id AS trip_key,
    t.trip_id,
    t.route_id,
    t.service_id,
    t.trip_headsign,
    t.direction_id,
    t.shape_id,
    s.start_time,
    s.end_time,
    s.stop_count,
    (s.end_time - s.start_time) AS trip_duration
FROM trips t
LEFT JOIN stop_times s
    ON t.trip_id = s.trip_id
