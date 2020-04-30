/****************** Assign bbl geometries ****************/
-- DELETE FROM edc_projects
-- WHERE excluded = 'TRUE';

ALTER TABLE edc_projects
    ADD source text,
    ADD record_id text,
    ADD record_name text,
    ADD status text,
    ADD type text,
    ADD units_gross text,
	ADD date text, -- Cluster date field
    ADD date_type text,
    ADD dcp_projectcompleted text, -- ZAP field
    ADD date_filed text, -- DOB field
    ADD date_permittd text, -- DOB field
    ADD date_lastupdt text, -- DOB field
    ADD date_complete text, -- DOB field
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(geometry,4326);

-- Merge with Mappluto using bbl
UPDATE edc_projects a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

-- assign bbl geometries to projects at block level
WITH boro_block AS(
	SELECT LEFT(bbl::TEXT, 6) AS bb,
	ST_UNION(wkb_geometry) AS geom
	FROM dcp_mappluto
	WHERE LEFT(bbl::TEXT, 6) IN(
		SELECT borough_code||lpad(block, 5, '0') AS bb
		FROM edc_projects
		WHERE borough_code IS NOT NULL
		AND block IS NOT NULL
		AND lot IS NULL
	)
	GROUP BY LEFT(bbl::TEXT, 6)
)

UPDATE edc_projects a
SET geom = b.geom
FROM boro_block b
WHERE a.borough_code||lpad(a.block, 5, '0') = b.bb
;

-- join sca_inputs to get shapefiles
UPDATE edc_projects a
SET geom = b.wkb_geometry
FROM edc_sca_inputs b
WHERE a.project_name = b.project_na;

-- backfill bbl using sca_inputs
UPDATE edc_projects a
SET bbl = b.bbl::TEXT
FROM dcp_mappluto b
WHERE a.geom = b.wkb_geometry;

-- backfill bbl using wkb_geometry
UPDATE edc_projects
SET geom = wkb_geometry
where geom is null;

/********************* Column Mapping *******************/
UPDATE edc_projects t
SET source = 'EDC Projected Projects',
    record_id = md5(CAST((t.*)AS text)),
    record_name = project_name,
    status = 'Projected',
    type = NULL,
    units_gross = total_units,
	date = build_year,
    date_type = 'Build Year',
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
-- column mapping
-- merge the records to project's level
DROP TABLE IF EXISTS edc_projects_proj;
CREATE TABLE edc_projects_proj AS(
	WITH geom_merge AS (
		SELECT record_id, ST_UNION(geom) AS geom
		FROM edc_projects
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
		FROM edc_projects) AS b
	ON a.record_id = b.record_id
);
