{{ config(schema='wh_cdc_nt') }}
WITH shapes AS (
    SELECT
        shape_id,
        shape_pt_lat,
        shape_pt_lon,
        shape_dist_traveled
    FROM {{ ref('dim_shapes') }}
),
shape_points AS (
    SELECT
        shape_id,
        COUNT(*) AS point_count,
        MIN(shape_pt_lat) AS min_lat,
        MAX(shape_pt_lat) AS max_lat,
        MIN(shape_pt_lon) AS min_lon,
        MAX(shape_pt_lon) AS max_lon,
        MAX(shape_dist_traveled::FLOAT) / 1000.0 AS total_length_km
    FROM shapes
    GROUP BY shape_id
)
SELECT *
FROM shape_points