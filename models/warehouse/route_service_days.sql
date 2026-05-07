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
        stop_count
    FROM {{ ref('trip_kpis') }}
),
bounds AS (
    SELECT
        st.trip_id,
        MIN(st.arrival_time) AS first_arrival,
        MAX(st.departure_time) AS last_departure
    FROM {{ ref('fact_stop_times') }} st
    GROUP BY st.trip_id
),
joined AS (
    SELECT
        t.route_id,
        t.date,
        t.monday,
        t.tuesday,
        t.wednesday,
        t.thursday,
        t.friday,
        t.saturday,
        t.sunday,
        b.first_arrival,
        b.last_departure
    FROM trips t
    LEFT JOIN bounds b ON t.trip_id = b.trip_id
),
summary AS (
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
        COUNT(*) AS total_trips,
        MIN(first_arrival) AS first_service_time,
        MAX(last_departure) AS last_service_time
    FROM joined
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
FROM summary
