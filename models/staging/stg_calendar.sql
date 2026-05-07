{{ config(schema='stg_cdc_nt') }}

SELECT
    service_id,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
    start_date,
    end_date,
    feed_id
FROM {{ source('cdc_nt', 'calendar') }}
