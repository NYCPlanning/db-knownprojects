/****************** Assign bbl geometries ****************/
ALTER TABLE dcp_n_study_projected
RENAME wkb_geometry TO geom;

ALTER TABLE dcp_n_study_projected
    ADD record_name text,
    ADD record_id text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD date text,
    ADD date_type text,
    ADD dcp_projectcompleted text,
    ADD date_filed text,
    ADD date_permittd text,
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
    record_id = project_id,
    record_name = REPLACE(project_id, ' Projected Development Sites', ''),
    project_status = 'Projected Development',
    project_type = NULL,
    number_of_units = total_unit,
    date = NULL,
    date_type = NULL,
    dcp_projectcompleted = NULL,
    date_filed = NULL,
    date_permittd = NULL,
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
		SELECT record_id, ST_UNION(geom) AS geom
		FROM dcp_n_study_projected
		GROUP BY record_id
	)
    SELECT b.source, b.record_id, b.record_name,
    b.project_status, b.project_type, b.inactive,
    b.number_of_units, b.date, b.date_type, b.dcp_projectcompleted,
    b.date_filed, b.date_permittd, b.date_lastupdt, b.date_complete,
    b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (record_id) *
		FROM dcp_n_study_projected) AS b
	ON a.record_id = b.record_id
);