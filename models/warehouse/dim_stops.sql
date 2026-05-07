{{ config(schema='wh_cdc_nt') }}

WITH stops AS (
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
    FROM {{ ref('stg_stops') }}
)

SELECT
    feed_id || '_' || stop_id AS stop_key,
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
FROM stops