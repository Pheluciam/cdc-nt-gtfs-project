{{ config(schema='int_cdc_nt') }}

WITH base_trips AS (
    SELECT
        route_id,
        service_id,
        trip_id,
        trip_headsign,
        direction_id::INTEGER AS direction_id,
        block_id,
        shape_id,
        feed_id
    FROM {{ ref('stg_trips') }}
),
routes AS (
    SELECT
        route_id,
        route_short_name,
        route_long_name,
        route_type,
        feed_id
    FROM {{ ref('int_routes') }}
)
SELECT
    t.route_id,
    t.service_id,
    t.trip_id,
    t.trip_headsign,
    t.direction_id,
    t.block_id,
    t.shape_id,
    r.route_short_name,
    r.route_long_name,
    r.route_type,
    t.feed_id
FROM base_trips t
LEFT JOIN routes r
    ON t.route_id = r.route_id
    AND t.feed_id = r.feed_id