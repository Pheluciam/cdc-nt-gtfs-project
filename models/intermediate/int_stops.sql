{{ config(schema='int_cdc_nt') }}

WITH base_stops AS (
    SELECT
        stop_id,
        stop_code,
        stop_name,
        stop_desc,
        stop_lat::NUMERIC AS stop_lat,
        stop_lon::NUMERIC AS stop_lon,
        zone_id,
        stop_url,
        location_type::INTEGER AS location_type,
        parent_station,
        feed_id
    FROM {{ ref('stg_stops') }}
)
SELECT
    stop_id,
    stop_code,
    stop_name,
    stop_desc,
    stop_lat,
    stop_lon,
    zone_id,
    stop_url,
    location_type,
    parent_station,
    feed_id
FROM base_stops