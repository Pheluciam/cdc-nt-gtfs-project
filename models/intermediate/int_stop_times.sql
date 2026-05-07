{{ config(schema='int_cdc_nt') }}

WITH src AS (
    SELECT
        feed_id,
        trip_id,
        stop_id,
        stop_sequence,
        arrival_time,
        departure_time,
        stop_headsign,
        pickup_type,
        drop_off_type,
        shape_dist_traveled,
        timepoint
    FROM {{ ref('stg_stop_times') }}
),
converted AS (
    SELECT
        feed_id,
        trip_id,
        stop_id,
        stop_sequence,
        CASE 
            WHEN split_part(arrival_time, ':', 1)::INT >= 24 THEN
                make_time(
                    split_part(arrival_time, ':', 1)::INT - 24,
                    split_part(arrival_time, ':', 2)::INT,
                    split_part(arrival_time, ':', 3)::INT
                )
            ELSE arrival_time::TIME
        END AS arrival_time,
        CASE 
            WHEN split_part(departure_time, ':', 1)::INT >= 24 THEN
                make_time(
                    split_part(departure_time, ':', 1)::INT - 24,
                    split_part(departure_time, ':', 2)::INT,
                    split_part(departure_time, ':', 3)::INT
                )
            ELSE departure_time::TIME
        END AS departure_time,
        stop_headsign,
        pickup_type,
        drop_off_type,
        shape_dist_traveled,
        timepoint
    FROM src
)
SELECT
    *
FROM converted
