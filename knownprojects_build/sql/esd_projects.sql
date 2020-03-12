/****************** Assign bbl geometries ****************/
ALTER TABLE esd_projects
RENAME source TO source_1;

ALTER TABLE esd_projects
    ADD source text,
    ADD project_id text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(Polygon,4326);

-- Merge with Mappluto using bbl
UPDATE esd_projects a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE esd_projects t
SET source = 'Empire State Development Projected Projects',
    project_id = project_name,
    project_status = 'Projected',
    project_type = NULL,
    number_of_units = total_units,
    portion_built_by_2025 = NULL,
    portion_built_by_2035 = NULL,
    portion_built_by_2055 = NULL,
    inactive = NULL
    ;

/************************ Merging ***********************/
-- merge the records to project's level
DROP TABLE IF EXISTS esd_projects_proj;
CREATE TABLE esd_projects_proj AS(
	WITH geom_merge AS (
		SELECT project_name, ST_UNION(geom) AS geom
		FROM esd_projects
		GROUP BY project_name
	)
	SELECT b.source, b.project_id, b.project_name,
    b.project_status, b.project_type,b.inactive,
	b.number_of_units, b.portion_built_by_2025,
	b.portion_built_by_2035, b.portion_built_by_2055,
	a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (project_name) *
		FROM esd_projects) AS b
	ON a.project_name = b.project_name
);