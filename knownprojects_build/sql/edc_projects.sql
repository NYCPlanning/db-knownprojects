/****************** Assign bbl geometries ****************/
DELETE FROM edc_projects
WHERE excluded = 'TRUE';

ALTER TABLE edc_projects
    ADD source text,
    ADD project_id text,
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

/********************* Column Mapping *******************/
UPDATE edc_projects t
SET source = 'EDC Projected Projects',
    project_id = edc_id,
    project_status = 'Projected',
    project_type = NULL,
    number_of_units = total_units,
	date_projected = build_year,
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
-- column mapping
-- merge the records to project's level
DROP TABLE IF EXISTS edc_projects_proj;
CREATE TABLE edc_projects_proj AS(
	WITH geom_merge AS (
		SELECT project_id, ST_UNION(geom) AS geom
		FROM edc_projects
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
		FROM edc_projects) AS b
	ON a.project_id = b.project_id
);
