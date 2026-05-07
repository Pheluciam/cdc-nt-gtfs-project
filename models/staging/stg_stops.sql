{{ config(schema='stg_cdc_nt') }}

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
FROM {{ source('cdc_nt', 'stops') }}