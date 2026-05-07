{{ config(schema='wh_cdc_nt') }}

SELECT
    trip_id,
    stop_id,
    stop_sequence
FROM {{ ref('stg_stop_times') }}
ORDER BY
    trip_id,
    stop_sequence
