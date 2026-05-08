SELECT timeband, COUNT(DISTINCT timeband_sort) AS distinct_sorts
FROM wh_cdc_nt.trip_timebands
GROUP BY timeband
HAVING COUNT(DISTINCT timeband_sort) > 1;