{{ config(schema='int_cdc_nt') }}

SELECT
    agency_id,
    agency_name,
    agency_url,
    agency_timezone,
    agency_lang,
    agency_phone,
    feed_id
FROM {{ source('cdc_nt', 'agency') }}