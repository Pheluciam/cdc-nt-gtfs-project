{{ config(schema='wh_cdc_nt') }}

WITH expanded AS (
    SELECT
        service_id,
        (start_date::date + i) AS date
    FROM {{ ref('stg_calendar') }},
         generate_series(0, 3650) AS s(i)
    WHERE (start_date::date + i) <= end_date::date
)
SELECT
    e.service_id,
    e.date,
    d.monday,
    d.tuesday,
    d.wednesday,
    d.thursday,
    d.friday,
    d.saturday,
    d.sunday
FROM expanded e
JOIN {{ ref('stg_calendar') }} d
  ON e.service_id = d.service_id