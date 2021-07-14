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

-- define a new function for the intersection join based on this answer https://gis.stackexchange.com/a/89387
CREATE OR REPLACE FUNCTION PolygonalIntersection(a geometry, b geometry)
RETURNS geometry AS $$
SELECT ST_Collect(geom)
FROM 
(SELECT (ST_Dump(ST_Intersection(a, b))).geom 
UNION ALL
-- union in an empty polygon so we get an 
-- empty geometry instead of NULL if there
-- is are no polygons in the intersection
SELECT ST_GeomFromText('POLYGON EMPTY')) SQ
WHERE ST_GeometryType(geom) = 'ST_Polygon';
$$ LANGUAGE SQL;

-- Identify spatially overlapping non-DOB records
DROP TABLE IF EXISTS _project_record_ids;
DROP TABLE IF EXISTS dbscan;
DROP TABLE IF EXISTS project_record_join;
DROP TABLE IF EXISTS all_intersections;

SELECT 
	record_id, 
	geom,
	ST_ClusterDBSCAN(geom, 0, 1) OVER() AS id
INTO dbscan
FROM  combined
WHERE source NOT IN ('DOB', 'Neighborhood Study Rezoning Commitments', 'Future Neighborhood Studies', 'Neighborhood Study Projected Development Sites');

SELECT 
	a.record_id,
	COUNT(record_id) OVER(PARTITION BY id) as records_in_project,
	a.id,
	(a.geom IS NULL)::integer as no_geom,
	a.geom
INTO project_record_join
FROM dbscan a;

SELECT 
	ST_AsText(ST_PolygonalIntersection(a.geom, b.geom)) as intersect_geom
INTO all_intersections
FROM  project_record_join a, project_record_join b
WHERE a.record_id < b.record_id
AND a.records_in_project > 1
AND b.records_in_project > 1
AND a.no_geom = 0
AND b.no_geom = 0;

SELECT
	array_agg(a.record_id) as project_record_ids
INTO _project_record_ids
FROM project_record_join a, all_intersections b
WHERE ST_OVERLAPS(a.geom, b.intersect_geom)
AND a.id IS NOT NULL
GROUP BY a.id;