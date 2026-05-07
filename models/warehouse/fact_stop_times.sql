{{ config(schema='wh_cdc_nt') }}

WITH stop_times AS (
    SELECT
        trip_id,
        arrival_time,
        departure_time,
        stop_id,
        stop_sequence,
        stop_headsign,
        pickup_type,
        drop_off_type,
        shape_dist_traveled,
        feed_id
    FROM {{ ref('stg_stop_times') }}
)

SELECT
    CONCAT(trip_id, '_', stop_sequence) AS stop_time_key,
    feed_id || '_' || stop_id AS stop_key,
    trip_id,
    stop_id,
    stop_sequence,
    arrival_time,
    departure_time,
    stop_headsign,
    pickup_type,
    drop_off_type,
    shape_dist_traveled,
    feed_id
FROM stop_times