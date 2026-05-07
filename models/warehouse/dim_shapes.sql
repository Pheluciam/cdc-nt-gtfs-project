{{ config(schema='wh_cdc_nt') }}

SELECT
    shape_id,
    shape_pt_lat,
    shape_pt_lon,
    shape_pt_sequence,
    shape_dist_traveled
FROM {{ ref('stg_shapes') }}