/****************** Assign bbl geometries ****************/
ALTER TABLE dcp_n_study_projected
RENAME wkb_geometry TO geom;

ALTER TABLE dcp_n_study_projected
    ADD project_name text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD date text,
    ADD dcp_projectcompleted text,
    ADD complete_year text,
    ADD permit_year text,
    ADD date_filed text,
    ADD date_statusd text,
    ADD date_statusp text,
    ADD date_permittd text,
    ADD date_statusr text,
    ADD date_statusx text,
    ADD date_lastupdt text,
    ADD date_complete text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text
    ;

/********************* Column Mapping *******************/
UPDATE dcp_n_study_projected t
SET source = 'Neighborhood Study Projected Development Sites',
    project_name = REPLACE(project_id, ' Projected Development Sites', ''),
    project_status = 'Projected Development',
    project_type = NULL,
    number_of_units = total_unit,
    date = NULL,
    dcp_projectcompleted = NULL,
    complete_year = NULL,
    permit_year = NULL,
    date_filed = NULL,
    date_statusd = NULL,
    date_statusp = NULL,
    date_permittd = NULL,
    date_statusr = NULL,
    date_statusx = NULL,
    date_lastupdt = NULL,
    date_complete = NULL,
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
    b.project_status, b.project_type, b.inactive,
    b.number_of_units, b.date, b.dcp_projectcompleted,
    b.complete_year, b.permit_year, 
    b.date_filed, b.date_statusd,
    b.date_statusp, b.date_permittd, b.date_statusr,
    b.date_statusx, b.date_lastupdt, b.date_complete,
    b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (project_id) *
		FROM dcp_n_study_projected) AS b
	ON a.project_id = b.project_id
);