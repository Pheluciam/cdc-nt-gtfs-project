{{ config(schema='wh_cdc_nt') }}

WITH calendar_dates AS (
    SELECT
        service_id,
        date,
        exception_type
    FROM {{ ref('stg_calendar_dates') }}
)

SELECT
    CONCAT(service_id, '_', date) AS calendar_date_key,
    service_id,
    date,
    exception_type
FROM calendar_dates