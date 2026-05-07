{{ config(schema='int_cdc_nt') }}

WITH base_routes AS (
    SELECT
        route_id,
        agency_id,
        route_short_name,
        route_long_name,
        route_desc,
        route_type::INTEGER AS route_type,
        route_url,
        route_color,
        route_text_color,
        feed_id
    FROM {{ ref('stg_routes') }}
),
base_agency AS (
    SELECT
        agency_id,
        agency_name,
        agency_url,
        agency_timezone,
        feed_id
    FROM {{ ref('stg_agency') }}
)
SELECT
    r.route_id,
    r.agency_id,
    a.agency_name,
    r.route_short_name,
    r.route_long_name,
    r.route_desc,
    r.route_type,
    r.route_url,
    r.route_color,
    r.route_text_color,
    r.feed_id
FROM base_routes r
LEFT JOIN base_agency a
    ON r.agency_id = a.agency_id
    AND r.feed_id = a.feed_id
