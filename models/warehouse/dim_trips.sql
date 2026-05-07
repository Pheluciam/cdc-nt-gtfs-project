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
)

SELECT
    trip_id AS trip_key,
    trip_id,
    route_id,
    service_id,
    trip_headsign,
    direction_id,
    shape_id
FROM trips