{{ config(schema='stg_cdc_nt') }}

SELECT
    trip_id,
    route_id,
    service_id,
    trip_headsign,
    direction_id,
    block_id,
    shape_id,
    feed_id
FROM {{ source('cdc_nt', 'trips') }}
