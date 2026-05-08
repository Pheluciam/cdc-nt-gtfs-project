SELECT route_id, AVG(avg_speed_kmh) AS mean_speed
FROM wh_cdc_nt.trip_kpis
WHERE avg_speed_kmh IS NOT NULL
GROUP BY route_id
LIMIT 50;