/*
DESCRIPTION:
    Creates final table of project_inputs.
	Adds dcp_housing record_ids to the groups of records identified in _project_inputs.sql,
	as long as they haven't been tagged for removal.

	Adds additional DOB to non-DOB matches identified in the dob_match_review table.

	Finally, creates stand-alone projects in the project_inputs table. This includes
	dcp_housing records and _combined records that did not match with other records in the
	two stages of identifying spatial overlaps.

INPUTS: 
    dob_review(

    )
	POST-REVIEW: dob_match_corrections(

	)
    _project_inputs(

    )
	dcp_housing_poly(

	)
	_combined(

	)
OUTPUTS: 
    project_inputs(
        
    )
*/

-- Copy pre-DOB match _project_inputs into project_inputs;
SELECT * 
INTO project_inputs FROM _project_inputs;

/* Use dob_match_review to identify which DOB record_ids need
to get added to projects in the project_inputs table. */	
WITH 
dob_matches AS(
	SELECT DISTINCT
		record_id, 
		project_inputs
	FROM dob_review
	WHERE source = 'DOB'
),
matches_to_remove AS(
	SELECT 
		a.record_id, 
		a.project_inputs
	FROM dob_matches a
	JOIN dob_match_corrections b
	ON a.record_id = b.dob_id
	AND b.record_id = any(a.project_inputs)
	AND b.action = 'remove'
),
matches_to_add AS(
	SELECT 
		dob_id as record_id,
		record_id as record_id_match
	FROM dob_match_corrections
	WHERE action='add'
),
verified_matches AS (
	SELECT 
		record_id, 
		project_inputs[1] as record_id_match
	FROM dob_matches
	WHERE record_id||project_inputs::text
		NOT IN (SELECT record_id||project_inputs::text FROM matches_to_remove)
	UNION
	SELECT * FROM matches_to_add)
UPDATE project_inputs a
	SET project_inputs = array_append(a.project_inputs, b.record_id) 
	FROM verified_matches b
	WHERE b.record_id_match=any(a.project_inputs);

/* Add stand-alone projects. This includes unmatched DOB projects, as well as projects
from sources that were excluded from the non-DOB match process. */
INSERT INTO project_inputs
SELECT array_append(array[]::text[], record_id::text) as project_inputs
FROM dcp_housing_poly
WHERE record_id NOT IN (SELECT UNNEST(project_inputs) FROM project_inputs);

INSERT INTO project_inputs
SELECT array_append(array[]::text[], record_id::text) as project_inputs
FROM _combined
WHERE record_id NOT IN (SELECT UNNEST(project_inputs) FROM project_inputs);