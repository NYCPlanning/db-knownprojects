/****************** Assign bbl geometries ****************/
ALTER TABLE dcp_n_study_future
    ADD source text,
    ADD project_id text,
    ADD project_name text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD date_projected text,
    ADD date_closed text,
    ADD date_complete text,
    ADD date_filed text,
    ADD date_statusd text,
    ADD date_statusp text,
    ADD date_permittd text,
    ADD date_statusr text,
    ADD date_statusx text,
    ADD date_lastupdt text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(Polygon,4326);

-- join to nyc rezoning
UPDATE dcp_n_study_future a
SET geom = b.wkb_geometry
FROM dcp_rezoning b
WHERE a.neighborhood = b.study;

/********************* Column Mapping *******************/
UPDATE dcp_n_study_future t
SET source = 'Future Neighborhood Studies',
    project_id = neighborhood||' '||'Future Rezoning Development',
    project_name = neighborhood,
    project_status = 'Projected',
    project_type = 'Future Rezoning',
    number_of_units = incremental_units_with_certainty_factor,
    date_projected = effective_year,
    date_closed = NULL,
    date_complete = NULL,
    date_filed = NULL,
    date_statusd = NULL,
    date_statusp = NULL,
    date_permittd = NULL,
    date_statusr = NULL,
    date_statusx = NULL,
    date_lastupdt = NULL,
    portion_built_by_2025 = portion_built_2025,
    portion_built_by_2035 = portion_built_2035,
    portion_built_by_2055 = portion_built_2055,
    inactive = NULL
    ;

/************************ Merging ***********************/
-- merge the records to project's level
DROP TABLE IF EXISTS dcp_n_study_future_proj;
CREATE TABLE dcp_n_study_future_proj AS(
	WITH geom_merge AS (
		SELECT project_id, ST_UNION(geom) AS geom
		FROM dcp_n_study_future
		GROUP BY project_id
	)
	SELECT b.source, b.project_id, b.project_name,
    b.project_status, b.project_type, b.inactive,
    b.number_of_units, b.date_projected, b.date_closed,
    b.date_complete, b.date_filed, b.date_statusd,
    b.date_statusp, b.date_permittd, b.date_statusr,
    b.date_statusx, b.date_lastupdt, b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (project_id) *
		FROM dcp_n_study_future) AS b
	ON a.project_id = b.project_id
);
