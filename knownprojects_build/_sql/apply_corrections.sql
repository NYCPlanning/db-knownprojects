-- Clean empty strings from corrections file
UPDATE kpdb_corrections
SET old_value = nullif(old_value, ' '),
	new_value = nullif(new_value, ' ');

-- Remove records
DELETE FROM _combined a
USING kpdb_corrections.latest b
WHERE b.field = 'remove'
AND a.record_id = b.record_id;

-- Correct geometries
UPDATE _combined a
SET geom = ST_SetSRID(b.new_value, 4326)
FROM kpdb_corrections.spatial_latest b
WHERE b.field = 'geom'
AND a.record_id = b.record_id 
AND NOT ST_IsEmpty(b.new_value);

-- Correct record_name
UPDATE _combined a
SET record_name = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'record_name'
AND a.record_id = b.record_id 
AND ((a.record_name = b.old_value) OR (a.record_name IS NULL AND b.old_value IS NULL));

-- Correct borough, if new borough is in correct form
UPDATE _combined a
SET borough = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'borough'
AND a.record_id = b.record_id 
AND ((a.borough = b.old_value) OR (a.borough IS NULL AND b.old_value IS NULL))
AND b.new_value IN ('Manhattan','Brooklyn','Staten Island','Queens','Bronx');

-- Correct status
UPDATE _combined a
SET status = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'status'
AND a.record_id = b.record_id 
AND ((a.status = b.old_value) OR (a.status IS NULL AND b.old_value IS NULL));

-- Correct type
UPDATE _combined a
SET type = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'type'
AND a.record_id = b.record_id 
AND ((a.type = b.old_value) OR (a.type IS NULL AND b.old_value IS NULL));

-- Correct date, if formatted correctly
UPDATE _combined a
SET date = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'date'
AND a.record_id = b.record_id 
AND ((a.date = b.old_value) OR (a.date IS NULL AND b.old_value IS NULL))
AND b.new_value LIKE '____/__/__';

-- Correct date_type
UPDATE _combined a
SET date_type = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'date_type'
AND a.record_id = b.record_id 
AND ((a.date_type = b.old_value) OR (a.date_type IS NULL AND b.old_value IS NULL));

-- Correct units_gross
UPDATE _combined a
SET units_gross = b.new_value::numeric,
	units_net = b.new_value::numeric
FROM kpdb_corrections.latest b
WHERE b.field = 'units_gross'
AND a.record_id = b.record_id 
AND ((a.units_gross::numeric = b.old_value::numeric) OR (a.units_gross IS NULL AND b.old_value IS NULL));

-- Correct prop_within_5_years, checking that new value is between zero & one
UPDATE _combined a
SET prop_within_5_years = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'prop_within_5_years'
AND a.record_id = b.record_id 
AND ((a.prop_within_5_years = b.old_value) OR (a.prop_within_5_years IS NULL AND b.old_value IS NULL))
AND b.new_value::numeric <= 1 AND b.new_value::numeric >= 0;

-- Correct prop_5_to_10_years, checking that new value is between zero & one
UPDATE _combined a
SET prop_5_to_10_years = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'prop_5_to_10_years'
AND a.record_id = b.record_id 
AND ((a.prop_5_to_10_years = b.old_value) OR (a.prop_5_to_10_years IS NULL AND b.old_value IS NULL))
AND b.new_value::numeric <= 1 AND b.new_value::numeric >= 0;

-- Correct prop_after_10_years, checking that new value is between zero & one
UPDATE _combined a
SET prop_after_10_years = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'prop_after_10_years'
AND a.record_id = b.record_id 
AND ((a.prop_after_10_years = b.old_value) OR (a.prop_after_10_years IS NULL AND b.old_value IS NULL))
AND b.new_value::numeric <= 1 AND b.new_value::numeric >= 0;

-- Correct phasing_rationale
UPDATE _combined a
SET phasing_rationale = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'phasing_rationale'
AND a.record_id = b.record_id 
AND ((a.phasing_rationale = b.old_value) OR (a.phasing_rationale IS NULL AND b.old_value IS NULL));

-- Correct phasing_known, if new value is valid
UPDATE _combined a
SET phasing_known = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'phasing_known'
AND a.record_id = b.record_id 
AND ((a.phasing_known::text = b.old_value::text) OR (a.phasing_known IS NULL AND b.old_value IS NULL))
AND b.new_value::text IN ('0','1');

-- Correct nycha
UPDATE _combined a
SET nycha = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'nycha'
AND a.record_id = b.record_id 
AND ((a.nycha::text = b.old_value::text) OR (a.nycha IS NULL AND b.old_value IS NULL))
AND b.new_value::text IN ('0','1');

-- Correct gq
UPDATE _combined a
SET gq = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'gq'
AND a.record_id = b.record_id 
AND ((a.gq::text = b.old_value::text) OR (a.gq IS NULL AND b.old_value IS NULL))
AND b.new_value::text IN ('0','1');

-- Correct senior_housing
UPDATE _combined a
SET senior_housing = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'senior_housing'
AND a.record_id = b.record_id 
AND ((a.senior_housing::text = b.old_value::text) OR (a.senior_housing IS NULL AND b.old_value IS NULL))
AND b.new_value::text IN ('0','1');

-- Correct assisted_living
UPDATE _combined a
SET assisted_living = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'assisted_living'
AND a.record_id = b.record_id 
AND ((a.assisted_living::text = b.old_value::text) OR (a.assisted_living IS NULL AND b.old_value IS NULL))
AND b.new_value::text IN ('0','1');

-- Correct inactive
UPDATE _combined a
SET inactive = b.new_value
FROM kpdb_corrections.latest b
WHERE b.field = 'inactive'
AND a.record_id = b.record_id 
AND ((a.inactive::text = b.old_value::text) OR (a.inactive IS NULL AND b.old_value IS NULL))
AND (b.new_value::text IN ('0','1') OR b.new_value IS NULL);



/*
PHASING: Make sure proportions add up to 1
*/
UPDATE _combined
SET prop_within_5_years = (CASE WHEN (prop_5_to_10_years IS NULL 
                                   AND prop_after_10_years IS NULL) THEN NULL
                              ELSE 1-(COALESCE(prop_5_to_10_years::numeric, 0) + COALESCE(prop_after_10_years::numeric, 0))
                              END) 
WHERE prop_within_5_years IS NULL;

UPDATE _combined
SET prop_5_to_10_years = (CASE WHEN (prop_within_5_years IS NULL
                                   AND prop_after_10_years IS NULL) THEN NULL
                              ELSE 1-(prop_within_5_years::numeric + COALESCE(prop_after_10_years::numeric,  0))
                              END)
WHERE prop_5_to_10_years IS NULL;

UPDATE _combined
SET prop_after_10_years = (CASE WHEN (prop_within_5_years IS NULL
                                   AND prop_5_to_10_years IS NULL) THEN NULL
                              ELSE 1-(prop_within_5_years::numeric + prop_5_to_10_years::numeric)
                              END)
WHERE prop_after_10_years IS NULL;
