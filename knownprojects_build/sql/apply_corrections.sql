UPDATE kpdb_corrections
SET old_value = nullif(old_value, ' '),
	new_value = nullif(new_value, ' ');

-- Remove records
DELETE FROM kpdb."2020" a
USING kpdb_corrections.latest b
WHERE b.field = 'remove'
AND a.record_id = b.record_id;

-- Correct geometries
UPDATE kpdb."2020" a
SET geom = ST_SetSRID(b.new_value, 4326)
FROM kpdb_corrections.spatial_latest b
WHERE b.field = 'geom'
AND a.record_id = b.record_id 
AND ((ST_AsText(a.geom) = ST_AsText(ST_SetSRID(b.new_value, 4326))) OR (a.geom IS NULL AND b.old_value IS NULL))
AND NOT ST_IsEmpty(b.new_value);

-- Correct project_id
UPDATE kpdb."2020" a
SET project_id = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'project_id'
AND a.record_id = b.record_id 
AND a.project_id = b.old_value
AND SPLIT_PART(b.new_value, '-', 2) ~ '^[0-9\.]+$';

-- Correct record_name
UPDATE kpdb."2020" a
SET record_name = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'record_name'
AND a.record_id = b.record_id 
AND a.record_name = b.old_value;

-- Correct borough, if new borough is in correct form
UPDATE kpdb."2020" a
SET borough = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'borough'
AND a.record_id = b.record_id 
AND a.borough = b.old_value
AND b.new_value IN ('Manhattan','Brooklyn','Staten Island','Queens','Bronx');

-- Correct status
UPDATE kpdb."2020" a
SET status = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'status'
AND a.record_id = b.record_id 
AND a.status = b.old_value;

-- Correct type
UPDATE kpdb."2020" a
SET type = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'type'
AND a.record_id = b.record_id 
AND a.type = b.old_value;

-- Correct date, if formatted correctly
UPDATE kpdb."2020" a
SET date = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'date'
AND a.record_id = b.record_id 
AND a.date = b.old_value
AND b.new_value LIKE '____/__/__';

-- Correct date_type
UPDATE kpdb."2020" a
SET date_type = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'date_type'
AND a.record_id = b.record_id 
AND a.date_type = b.old_value;

-- Correct units_gross
UPDATE kpdb."2020" a
SET units_gross = b.new_value::numeric,
	units_net = b.new_value::numeric
FROM kpdb_corrections.latest b
WHERE b.field = 'units_gross'
AND a.record_id = b.record_id 
AND a.units_gross::numeric = b.old_value::numeric;

-- Correct prop_within_5_years, checking that new value is between zero & one
UPDATE kpdb."2020" a
SET prop_within_5_years = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'prop_within_5_years'
AND a.record_id = b.record_id 
AND a.prop_within_5_years = b.old_value
AND b.new_value::numeric <= 1 AND b.new_value::numeric >= 0;

-- Correct prop_5_to_10_years, checking that new value is between zero & one
UPDATE kpdb."2020" a
SET prop_5_to_10_years = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'prop_5_to_10_years'
AND a.record_id = b.record_id 
AND a.prop_5_to_10_years = b.old_value
AND b.new_value::numeric <= 1 AND b.new_value::numeric >= 0;

-- Correct prop_after_10_years, checking that new value is between zero & one
UPDATE kpdb."2020" a
SET prop_after_10_years = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'prop_after_10_years'
AND a.record_id = b.record_id 
AND a.prop_after_10_years = b.old_value
AND b.new_value::numeric <= 1 AND b.new_value::numeric >= 0;

-- Correct phasing_rationale
UPDATE kpdb."2020" a
SET phasing_rationale = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'phasing_rationale'
AND a.record_id = b.record_id 
AND a.phasing_rationale = b.old_value;

-- Correct phasing_known, if new value is valid
UPDATE kpdb."2020" a
SET phasing_known = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'phasing_known'
AND a.record_id = b.record_id 
AND a.phasing_known::text = b.old_value::text
AND b.new_value::text IN ('0','1');

-- Correct nycha
UPDATE kpdb."2020" a
SET nycha = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'nycha'
AND a.record_id = b.record_id 
AND a.nycha::text = b.old_value::text
AND b.new_value::text IN ('0','1');

-- Correct gq
UPDATE kpdb."2020" a
SET gq = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'gq'
AND a.record_id = b.record_id 
AND a.gq::text = b.old_value::text
AND b.new_value::text IN ('0','1');

-- Correct senior_housing
UPDATE kpdb."2020" a
SET senior_housing = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'senior_housing'
AND a.record_id = b.record_id 
AND a.senior_housing::text = b.old_value::text
AND b.new_value::text IN ('0','1');

-- Correct assisted_living
UPDATE kpdb."2020" a
SET assisted_living = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'assisted_living'
AND a.record_id = b.record_id 
AND a.assisted_living::text = b.old_value::text
AND b.new_value::text IN ('0','1');

-- Correct inactive
UPDATE kpdb."2020" a
SET inactive = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'inactive'
AND a.record_id = b.record_id 
AND a.inactive::text = b.old_value::text
AND (b.new_value::text IN ('0','1') OR b.new_value IS NULL);