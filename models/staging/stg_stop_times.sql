{{ config(schema='stg_cdc_nt') }}

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
    timepoint,
    feed_id
FROM {{ source('cdc_nt', 'stop_times') }}