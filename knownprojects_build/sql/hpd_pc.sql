/****************** Assign bbl geometries ****************/
ALTER TABLE hpd_pc
    ADD source text,
    ADD record_id text,
    ADD record_name text,
    ADD status text,
    ADD type text,
    ADD units_gross text,
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
UPDATE hpd_pc a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE hpd_pc t
SET source = 'HPD Projected Closings',
    record_id = project_id||'/'||building_id,
    record_name = house_number||' '||street_name,
    status = 'Projected',
    type = NULL,
    units_gross = (min_of_projected_units::INTEGER + max_of_projected_units::INTEGER)/2,
    date = projected_fiscal_year_range,
    date_type = 'Projected Fiscal Year Range',
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
DROP TABLE IF EXISTS hpd_pc_proj;
CREATE TABLE hpd_pc_proj AS(
	WITH geom_merge AS (
		SELECT record_id, ST_UNION(geom) AS geom
		FROM hpd_pc
		GROUP BY record_id
	)
	SELECT b.source, b.record_id, b.record_name,
    b.status, b.type, b.inactive,
    b.units_gross, b.date, b.date_type, b.dcp_projectcompleted,
    b.date_filed, b.date_permittd,
    b.date_lastupdt, b.date_complete,
    b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (record_id) *
		FROM hpd_pc) AS b
	ON a.record_id = b.record_id
);