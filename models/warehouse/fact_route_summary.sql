{{ config(schema='wh_cdc_nt') }}

WITH trip_counts AS (
    SELECT
        route_id,
        COUNT(*) AS total_trips
    FROM {{ ref('stg_trips') }}
    GROUP BY route_id
),
stop_counts AS (
    SELECT
        t.route_id,
        COUNT(DISTINCT st.stop_id) AS unique_stops,
        COUNT(*) AS total_stop_events
    FROM {{ ref('stg_trips') }} t
    JOIN {{ ref('stg_stop_times') }} st
      ON t.trip_id = st.trip_id
    GROUP BY t.route_id
),
service_span AS (
    SELECT
        t.route_id,
        MIN(st.arrival_time) AS first_arrival,
        MAX(st.arrival_time) AS last_arrival
    FROM {{ ref('stg_trips') }} t
    JOIN {{ ref('stg_stop_times') }} st
      ON t.trip_id = st.trip_id
    GROUP BY t.route_id
)
SELECT
    r.route_id,
    r.route_short_name,
    r.route_long_name,
    tc.total_trips,
    sc.unique_stops,
    sc.total_stop_events,
    ss.first_arrival,
    ss.last_arrival
FROM {{ ref('stg_routes') }} r
LEFT JOIN trip_counts tc ON r.route_id = tc.route_id
LEFT JOIN stop_counts sc ON r.route_id = sc.route_id
LEFT JOIN service_span ss ON r.route_id = ss.route_id