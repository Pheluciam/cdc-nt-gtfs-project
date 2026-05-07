{{ config(schema='stg_cdc_nt') }}

SELECT
    shape_id,
    shape_pt_lat,
    shape_pt_lon,
    shape_pt_sequence,
    shape_dist_traveled,
    feed_id
FROM {{ source('cdc_nt', 'shapes') }}
