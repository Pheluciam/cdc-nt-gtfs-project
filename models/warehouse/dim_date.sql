{{ config(schema='wh_cdc_nt') }}

WITH date_series AS (
    SELECT
        (DATE '2024-01-01' + i) AS date
    FROM generate_series(0, 365 * 5) AS s(i)
)
SELECT
    date,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    EXTRACT(DAY FROM date) AS day,
    TO_CHAR(date, 'Day') AS day_of_week
FROM date_series