/****************** Assign bbl geometries ****************/
ALTER TABLE dcp_n_study
    ADD source text,
    ADD project_id text,
    ADD project_name text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(Polygon,4326);

-- Merge with Mappluto using bbl
UPDATE dcp_n_study a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE dcp_n_study t
SET source = 'Neighborhood Study Rezoning Commitments',
    project_id = neighborhood_study||' Rezoning Commitment',
    project_name = commitment_site,
    project_status = 'Rezoning Commitment',
    project_type = NULL,
    portion_built_by_2025 = NULL,
    portion_built_by_2035 = NULL,
    portion_built_by_2055 = NULL,
    inactive = NULL
    ;

UPDATE dcp_n_study a
SET number_of_units = b.total_units
FROM dcp_knownprojects b
WHERE a.project_name = b.project_name_address
AND b.source = 'Neighborhood Study Rezoning Commitments'
;

/************************ Merging ***********************/
-- column mapping
-- merge the records to project's level
DROP TABLE IF EXISTS dcp_n_study_proj;
CREATE TABLE dcp_n_study_proj AS(
	WITH geom_merge AS (
		SELECT project_id, project_name, ST_UNION(geom) AS geom
		FROM dcp_n_study
		GROUP BY project_id, project_name
	)
	SELECT b.source, b.project_id, b.project_name,
    b.project_status, b.project_type,b.inactive,
	b.number_of_units, b.portion_built_by_2025,
	b.portion_built_by_2035, b.portion_built_by_2055,
	a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (project_id, project_name) *
		FROM dcp_n_study) AS b
	ON a.project_id = b.project_id
    AND a.project_name = b.project_name
);