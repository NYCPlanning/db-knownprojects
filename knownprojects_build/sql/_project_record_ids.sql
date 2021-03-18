/*
DESCRIPTION:
    Create initial table of project inputs (groups of record_ids that refer to the
    same project). Match non-DOB records based on spatial overlap,
    forming arrays of individual record_ids which get called
    project_record_ids. Two of the neighborhood study sources are not
    included, as units from these sources do not deduplicate
    with other sources.

INPUTS: 
	combined
    corrections_project (POST-REVIEW)
OUTPUTS: 
    _project_record_ids
*/

-- Identify spatially overlapping non-DOB records
DROP TABLE IF EXISTS _project_record_ids;
SELECT
    array_agg(record_id) as project_record_ids
INTO _project_record_ids
FROM(
    SELECT record_id, 
    ST_ClusterDBSCAN(geom, 0, 1) OVER() AS id
    FROM  combined
    WHERE source NOT IN ('DOB', 'Neighborhood Study Rezoning Commitments', 'Future Neighborhood Studies')
) a
WHERE id IS NOT NULL
GROUP BY id;