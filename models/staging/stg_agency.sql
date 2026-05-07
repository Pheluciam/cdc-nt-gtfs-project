{{ config(schema='stg_cdc_nt') }}

SELECT
    agency_id,
    agency_name,
    agency_url,
    agency_timezone,
    feed_id
FROM {{ source('cdc_nt', 'agency') }}
