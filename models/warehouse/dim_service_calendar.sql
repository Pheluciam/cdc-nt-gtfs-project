{{ config(schema='wh_cdc_nt') }}

SELECT
    service_id,
    start_date,
    end_date,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday
FROM {{ ref('stg_calendar') }}