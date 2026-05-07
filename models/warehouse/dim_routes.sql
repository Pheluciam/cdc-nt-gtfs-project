{{ config(schema='wh_cdc_nt') }}

WITH routes AS (
    SELECT
        route_id,
        agency_id,
        route_short_name,
        route_long_name,
        route_type,
        route_color,
        route_text_color,
        feed_id
    FROM {{ ref('stg_routes') }}
)

SELECT
    route_id AS route_key,
    feed_id || '_' || agency_id AS agency_key,
    route_id,
    agency_id,
    route_short_name,
    route_long_name,
    route_type,
    route_color,
    route_text_color,
    feed_id
FROM routes