/*
DESCRIPTION:
    Creates final table of project_record_ids.
	Adds dcp_housing record_ids to the groups of records identified in _project_record_ids.sql,
	as long as they haven't been tagged for removal.

	Adds additional DOB to non-DOB matches identified in the correction_dob_match table.

	Finally, creates stand-alone projects in the project_record_ids table. This includes
	dcp_housing records and combined records that did not match with other records in the
	two stages of identifying spatial overlaps.

INPUTS: 
    _review_dob
	corrections_dob_match (POST-REVIEW)
    _project_record_ids
	dcp_housing_poly
	combined
OUTPUTS:
    project_record_ids
*/

-- Copy pre-DOB match _project_record_ids into project_record_ids;
DROP TABLE IF EXISTS project_record_ids;
SELECT * INTO project_record_ids 
FROM _project_record_ids;

/* Use correction_dob_match to identify which DOB record_ids need
to get added to projects in the project_record_ids table. */	
WITH 
dob_matches AS(
	SELECT DISTINCT
		record_id, 
		project_record_ids
	FROM _review_dob
	WHERE source = 'DOB'
	AND no_classa = '0'
),
matches_to_remove AS(
	SELECT 
		a.record_id, 
		a.project_record_ids
	FROM dob_matches a
	JOIN corrections_dob_match b
	ON a.record_id = b.record_id_dob
	AND b.record_id = any(a.project_record_ids)
	AND b.action = 'remove'
),
matches_to_add AS(
	SELECT 
		record_id_dob as record_id,
		record_id as record_id_match
	FROM corrections_dob_match
	WHERE action = 'add'
),
verified_matches AS (
	SELECT 
		record_id, 
		project_record_ids[1] as record_id_match
	FROM dob_matches
	WHERE record_id||project_record_ids::text
		NOT IN (SELECT record_id||project_record_ids::text FROM matches_to_remove)
	UNION
	SELECT * FROM matches_to_add)
UPDATE project_record_ids a
	SET project_record_ids = a.project_record_ids||b.record_id
	FROM verified_matches b
	WHERE b.record_id_match=any(a.project_record_ids);

/* Add stand-alone projects. This includes unmatched residential DOB projects, 
as well as projects from sources that were excluded 
from the non-DOB match process. */
INSERT INTO project_record_ids
SELECT array[]::text[]||record_id as project_record_ids
FROM (
	SELECT record_id::text from combined
	WHERE no_classa = '0' OR no_classa IS NULL
) a
WHERE record_id NOT IN (SELECT UNNEST(project_record_ids) FROM project_record_ids);