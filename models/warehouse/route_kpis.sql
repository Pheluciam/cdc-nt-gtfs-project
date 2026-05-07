{{ config(schema='wh_cdc_nt') }}

WITH trips AS (
    SELECT
        trip_id,
        route_id,
        date,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        stop_count,
        total_distance_km,
        kms,
        avg_speed_kmh
    FROM {{ ref('trip_kpis') }}
),
route_summary AS (
    SELECT
        route_id,
        date,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        COUNT(trip_id) AS total_trips,
        SUM(total_distance_km) AS total_distance_km,
        AVG(total_distance_km) AS avg_distance_km,
        AVG(avg_speed_kmh) AS avg_speed_kmh,
        AVG(stop_count) AS avg_stops_per_trip
    FROM trips
    GROUP BY
        route_id,
        date,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday
)
SELECT *
FROM route_summary