{{ config(schema='int_cdc_nt') }}

WITH base_shapes AS (
    SELECT
        shape_id,
        shape_pt_lat::NUMERIC AS shape_pt_lat,
        shape_pt_lon::NUMERIC AS shape_pt_lon,
        shape_pt_sequence::INTEGER AS shape_pt_sequence,
        shape_dist_traveled::NUMERIC AS shape_dist_traveled,
        feed_id
    FROM {{ ref('stg_shapes') }}
)
SELECT
    shape_id,
    shape_pt_lat,
    shape_pt_lon,
    shape_pt_sequence,
    shape_dist_traveled,
    feed_id
FROM base_shapes