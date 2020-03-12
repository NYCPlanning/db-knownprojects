/****************** Assign bbl geometries ****************/
ALTER TABLE esd_projects
RENAME wkb_geometry TO geom;

ALTER TABLE dcp_n_study_projected
    ADD project_name text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(Polygon,4326);

/********************* Column Mapping *******************/
UPDATE dcp_n_study_projected t
SET source = 'Neighborhood Study Projected Development Sites',
    project_name = REPLACE(project_id, ' Projected Development Sites', ''),
    project_status = 'Projected Development',
    project_type = NULL,
    number_of_units = total_unit,
    portion_built_by_2025 = portion_bu,
    portion_built_by_2035 = portion__1,
    portion_built_by_2055 = portion__2,
    inactive = NULL
    ;

/************************ Merging ***********************/
-- merge the records to project's level
DROP TABLE IF EXISTS dcp_n_study_projected_proj;
CREATE TABLE dcp_n_study_projected_proj AS(
	WITH geom_merge AS (
		SELECT project_id, ST_UNION(geom) AS geom
		FROM dcp_n_study_projected
		GROUP BY project_id
	)
	SELECT b.source, b.project_id, b.project_name,
    b.project_status, b.project_type,b.inactive,
	b.number_of_units, b.portion_built_by_2025,
	b.portion_built_by_2035, b.portion_built_by_2055,
	a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (project_id) *
		FROM dcp_n_study_projected) AS b
	ON a.project_id = b.project_id
);