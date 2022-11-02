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
OUTPUTS: 
    _project_record_ids
*/

-- Identify spatially overlapping non-DOB records
DROP TABLE IF EXISTS _project_record_ids;
WITH
dbscan AS (
    SELECT 
        record_id, 
        geom,
        ST_ClusterDBSCAN(geom, 0, 1) OVER() AS id
    FROM  combined
    WHERE source NOT IN ('DOB', 'Neighborhood Study Rezoning Commitments', 'Future Neighborhood Studies')
),
project_record_join AS (
	SELECT 
	    a.record_id,
	    COUNT(record_id) OVER(PARTITION BY id) as records_in_project,
	    a.id,
	    (a.geom IS NULL)::integer as no_geom,
	    a.geom
	FROM dbscan a
),
all_intersections AS (
	SELECT 
		ST_UNION(ST_INTERSECTION(a.geom, b.geom)) as intersect_geom
	FROM  project_record_join a, project_record_join b
	WHERE a.record_id < b.record_id
	AND a.records_in_project > 1
	AND b.records_in_project > 1
	AND a.no_geom = 0
	AND b.no_geom = 0
)
SELECT
	array_agg(a.record_id) as project_record_ids
INTO _project_record_ids
FROM project_record_join a, all_intersections b
WHERE (ST_OVERLAPS(a.geom, b.intersect_geom) OR b.intersect_geom IS NULL)
AND a.id IS NOT NULL
GROUP BY a.id;