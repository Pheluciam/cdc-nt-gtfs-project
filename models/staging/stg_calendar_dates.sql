{{ config(schema='stg_cdc_nt') }}

SELECT
    service_id,
    date,
    exception_type,
    feed_id
FROM {{ source('cdc_nt', 'calendar_dates') }}
