{{ config(schema='wh_cdc_nt') }}

SELECT
    feed_id || '_' || agency_id AS agency_key,
    agency_id,
    agency_name,
    agency_url,
    agency_timezone,
    agency_lang,
    agency_phone,
    feed_id
FROM {{ ref('int_agency') }}