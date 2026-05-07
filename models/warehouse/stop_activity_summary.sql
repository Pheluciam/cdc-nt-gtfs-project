{{ config(schema='wh_cdc_nt') }}

WITH stop_times AS (
    SELECT
        st.trip_id,
        st.stop_id,
        st.arrival_time,
        st.departure_time
    FROM {{ ref('fact_stop_times') }} st
),
trips AS (
    SELECT
        trip_id,
        date,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        kms
    FROM {{ ref('trip_kpis') }}
),
joined AS (
    SELECT
        st.stop_id,
        t.date,
        t.monday,
        t.tuesday,
        t.wednesday,
        t.thursday,
        t.friday,
        t.saturday,
        t.sunday,
        st.arrival_time,
        st.departure_time,
        t.kms
    FROM stop_times st
    LEFT JOIN trips t ON st.trip_id = t.trip_id
),
summary AS (
    SELECT
        stop_id,
        date,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        COUNT(*) AS total_stop_events,
        MIN(arrival_time) AS first_service_time,
        MAX(departure_time) AS last_service_time,
        AVG(kms) AS avg_trip_distance_km
    FROM joined
    GROUP BY
        stop_id,
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