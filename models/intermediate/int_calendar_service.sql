{{ config(schema='int_cdc_nt') }}

WITH base_calendar AS (
    SELECT
        service_id,
        monday::INTEGER AS monday,
        tuesday::INTEGER AS tuesday,
        wednesday::INTEGER AS wednesday,
        thursday::INTEGER AS thursday,
        friday::INTEGER AS friday,
        saturday::INTEGER AS saturday,
        sunday::INTEGER AS sunday,
        TO_DATE(start_date, 'YYYYMMDD') AS start_date,
        TO_DATE(end_date, 'YYYYMMDD') AS end_date,
        feed_id
    FROM {{ ref('stg_calendar') }}
),
base_calendar_dates AS (
    SELECT
        service_id,
        TO_DATE(date, 'YYYYMMDD') AS date,
        exception_type::INTEGER AS exception_type,
        feed_id
    FROM {{ ref('stg_calendar_dates') }}
),
expanded_calendar AS (
    SELECT
        c.service_id,
        d.date,
        CASE
            WHEN d.exception_type = 1 THEN 1
            WHEN d.exception_type = 2 THEN 0
            ELSE
                CASE
                    WHEN EXTRACT(DOW FROM d.date) = 1 THEN c.monday
                    WHEN EXTRACT(DOW FROM d.date) = 2 THEN c.tuesday
                    WHEN EXTRACT(DOW FROM d.date) = 3 THEN c.wednesday
                    WHEN EXTRACT(DOW FROM d.date) = 4 THEN c.thursday
                    WHEN EXTRACT(DOW FROM d.date) = 5 THEN c.friday
                    WHEN EXTRACT(DOW FROM d.date) = 6 THEN c.saturday
                    WHEN EXTRACT(DOW FROM d.date) = 0 THEN c.sunday
                END
        END AS is_service_day,
        c.feed_id
    FROM base_calendar c
    JOIN base_calendar_dates d
        ON c.service_id = d.service_id
)
SELECT
    service_id,
    date,
    is_service_day,
    feed_id
FROM expanded_calendar
