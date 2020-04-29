/****************** Assign bbl geometries ****************/
ALTER TABLE dcp_n_study_future
    ADD source text,
    ADD record_id text,
    ADD record_name text,
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
    ADD inactive text,
    ADD geom geometry(geometry,4326);

-- join to nyc rezoning
UPDATE dcp_n_study_future a
SET geom = b.wkb_geometry
FROM dcp_rezoning b
WHERE a.neighborhood = b.study;

/********************* Column Mapping *******************/
UPDATE dcp_n_study_future t
SET source = 'Future Neighborhood Studies',
    record_id = md5(CAST((t.*)AS text)),
    record_name = neighborhood||' '||'Future Rezoning Development',
    project_status = 'Projected',
    project_type = 'Future Rezoning',
    number_of_units = incremental_units_with_certainty_factor,
    date = effective_year,
    date_type = 'Effective Year',
    dcp_projectcompleted = NULL,
    date_filed = NULL,
    date_permittd = NULL,
    date_lastupdt = NULL,
    date_complete = NULL,
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
		SELECT record_id, ST_UNION(geom) AS geom
		FROM dcp_n_study_future
		GROUP BY record_id
	)
	SELECT b.source, b.record_id, b.record_name,
    b.project_status, b.project_type, b.inactive,
    b.number_of_units, b.date, b.date_type, b.dcp_projectcompleted,
    b.date_filed, b.date_permittd, 
    b.date_lastupdt, b.date_complete,
    b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (record_id) *
		FROM dcp_n_study_future) AS b
	ON a.record_id = b.record_id
);
