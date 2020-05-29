-- Force a correction of units_net

UPDATE kpdb."2020" a
SET units_net = b.new_value::numeric
FROM kpdb_corrections.latest b
WHERE b.field = 'units_net'
AND a.record_id = b.record_id 
AND ((a.units_net::numeric = b.old_value::numeric) OR (a.units_net IS NULL and b.old_value IS NULL));