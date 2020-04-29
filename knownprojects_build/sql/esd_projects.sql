/****************** Assign bbl geometries ****************/
ALTER TABLE esd_projects
RENAME source TO source_1;

ALTER TABLE esd_projects
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

-- Merge with Mappluto using bbl
UPDATE esd_projects a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE esd_projects t
SET source = 'Empire State Development Projected Projects',
    record_id = md5(CAST((t.*)AS text)),
    record_name = project_name,
    project_status = 'Projected',
    project_type = NULL,
    number_of_units = total_units,
	date = NULL,
    date_type = NULL,
    dcp_projectcompleted = NULL,
    date_filed = NULL,
    date_permittd = NULL,
    date_lastupdt = NULL,
    date_complete = NULL,
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
		SELECT record_name, ST_UNION(geom) AS geom
		FROM esd_projects
		GROUP BY record_name
	)
	SELECT b.source, b.record_id, b.record_name,
    b.project_status, b.project_type, b.inactive,
    b.number_of_units, b.date, b.date_type, b.dcp_projectcompleted, 
    b.date_filed,b.date_permittd, b.date_lastupdt, b.date_complete,
    b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (record_name) *
		FROM esd_projects) AS b
	ON a.record_name = b.record_name
);