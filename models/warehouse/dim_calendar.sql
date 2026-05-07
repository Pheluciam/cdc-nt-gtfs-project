{{ config(schema='wh_cdc_nt') }}

WITH calendar AS (
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
        end_date
    FROM {{ ref('stg_calendar') }}
)

SELECT
    service_id AS service_key,
    service_id,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
    start_date,
    end_date
FROM calendar