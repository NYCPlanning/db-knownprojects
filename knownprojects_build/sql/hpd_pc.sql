/****************** Assign bbl geometries ****************/
ALTER TABLE hpd_pc
    ADD source text,
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

-- Merge with Mappluto using bbl
UPDATE hpd_pc a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE hpd_pc t
SET source = 'HPD Projected Closings',
    project_id = project_id||'/'||building_id,
    project_name = house_number||' '||street_name,
    project_status = 'Projected',
    project_type = NULL,
    number_of_units = (min_of_projected_units::INTEGER + max_of_projected_units::INTEGER)/2,
    date_projected = projected_fiscal_year_range,
    date_closed = NULL,
    date_complete = NULL,
    date_filed = NULL,
    date_statusd = NULL,
    date_statusp = NULL,
    date_permittd = NULL,
    date_statusr = NULL,
    date_statusx = NULL,
    date_lastupdt = NULL,
    portion_built_by_2025 = NULL,
    portion_built_by_2035 = NULL,
    portion_built_by_2055 = NULL,
    inactive = NULL
    ;

/************************ Merging ***********************/
-- merge the records to project's level
DROP TABLE IF EXISTS hpd_pc_proj;
CREATE TABLE hpd_pc_proj AS(
	WITH geom_merge AS (
		SELECT project_id, ST_UNION(geom) AS geom
		FROM hpd_pc
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
		FROM hpd_pc) AS b
	ON a.project_id = b.project_id
);