{{ config(schema='wh_cdc_nt') }}

WITH trips AS (
    SELECT
        t.trip_id,
        t.route_id,
        t.service_id,
        t.direction_id,
        t.shape_id,
        t.trip_headsign
    FROM {{ ref('dim_trips') }} t
),
stop_times AS (
    SELECT
        st.trip_id,
        st.arrival_time,
        st.departure_time,
        st.stop_sequence,
        st.shape_dist_traveled
    FROM {{ ref('fact_stop_times') }} st
),
trip_bounds AS (
    SELECT
        trip_id,
        MIN(arrival_time) AS first_arrival,
        MAX(departure_time) AS last_departure,
        COUNT(*) AS stop_count,
        MAX(shape_dist_traveled)::FLOAT AS total_distance_m
    FROM stop_times
    GROUP BY trip_id
),
service_days AS (
    SELECT
        service_id,
        date,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday
    FROM {{ ref('fact_service_days') }}
),
kpis AS (
    SELECT
        t.trip_id,
        t.route_id,
        t.service_id,
        sd.date,
        sd.monday,
        sd.tuesday,
        sd.wednesday,
        sd.thursday,
        sd.friday,
        sd.saturday,
        sd.sunday,
        t.direction_id,
        t.shape_id,
        t.trip_headsign,
        b.stop_count,
        b.total_distance_m / 1000.0 AS total_distance_km,
        CASE
            WHEN b.total_distance_m > 0
            THEN b.total_distance_m / 1000.0
            ELSE NULL
        END AS kms,
        CASE
            WHEN b.total_distance_m > 0
             AND b.last_departure IS NOT NULL
             AND b.first_arrival IS NOT NULL
             AND (b.last_departure::time > b.first_arrival::time)
            THEN (b.total_distance_m / 1000.0) /
                 ((EXTRACT(EPOCH FROM (b.last_departure::time - b.first_arrival::time))) / 3600.0)
            ELSE NULL
        END AS avg_speed_kmh
    FROM trips t
    LEFT JOIN trip_bounds b ON t.trip_id = b.trip_id
    LEFT JOIN service_days sd ON t.service_id = sd.service_id
)
SELECT *
FROM kpis