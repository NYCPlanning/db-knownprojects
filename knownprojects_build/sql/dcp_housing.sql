/****************** Assign bbl geometries ****************/
ALTER TABLE dcp_housing
RENAME geom TO wkb_geometry;

ALTER TABLE dcp_housing
    ADD source text,
    ADD record_id text,
    ADD record_name text,
    ADD borough text,
    ADD status text,
    ADD type text,
    ADD units_gross text,
    ADD date text,
    ADD date_type text,
    ADD dcp_projectcompleted text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(geometry,4326);

-- Merge with Mappluto using bbl
UPDATE dcp_housing a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

-- spatial join with Mappluto
UPDATE dcp_housing a
SET bbl = b.bbl,
    geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE ST_Within(a.wkb_geometry,b.wkb_geometry)
AND a.wkb_geometry IS NOT NULL
AND a.geom IS NULL;

/********************* Column Mapping *******************/
UPDATE dcp_housing t
SET source = 'DOB',
    record_id = job_number,
    record_name = address,
    status = job_status,
    type = job_type,
    units_gross = units_net,
    date = CASE
            WHEN date_permittd IS NULL THEN NULL
            WHEN  date_permittd LIKE '%-%' THEN TO_CHAR(TO_DATE(date_permittd, 'YYYY-MM-DD'), 'YYYY/MM/DD')
            ELSE TO_CHAR(TO_DATE(date_permittd, 'MM/DD/YYYY'), 'YYYY/MM/DD')
        END,
    date_type = 'Date Permitted',
    date_filed = CASE
            WHEN date_filed IS NULL THEN NULL
            WHEN  date_filed LIKE '%-%' THEN TO_CHAR(TO_DATE(date_filed, 'YYYY-MM-DD'), 'YYYY/MM/DD')
            ELSE TO_CHAR(TO_DATE(date_filed, 'MM/DD/YYYY'), 'YYYY/MM/DD')
        END,
    date_lastupdt = CASE
            WHEN date_lastupdt IS NULL THEN NULL
            WHEN  date_lastupdt LIKE '%-%' THEN TO_CHAR(TO_DATE(date_lastupdt, 'YYYY-MM-DD'), 'YYYY/MM/DD')
            ELSE TO_CHAR(TO_DATE(date_lastupdt, 'MM/DD/YYYY'), 'YYYY/MM/DD')
        END,
    date_complete = CASE
            WHEN date_complete IS NULL THEN NULL
            WHEN  date_complete LIKE '%-%' THEN TO_CHAR(TO_DATE(date_complete, 'YYYY-MM-DD'), 'YYYY/MM/DD')
            ELSE TO_CHAR(TO_DATE(date_complete, 'MM/DD/YYYY'), 'YYYY/MM/DD')
        END,
    dcp_projectcompleted = NULL,
    portion_built_by_2025 = NULL,
    portion_built_by_2035 = NULL,
    portion_built_by_2055 = NULL,
    inactive = (CASE WHEN job_inactive = 'Inactive' THEN 1 ELSE 0 END)
    ;

/************************ Merging ***********************/
-- merge the records to project's level
DROP TABLE IF EXISTS dcp_housing_proj;
CREATE TABLE dcp_housing_proj AS(
	WITH geom_merge AS (
		SELECT record_id, ST_UNION(geom) AS geom
		FROM dcp_housing
		GROUP BY record_id
	)
	SELECT b.source, b.record_id, b.record_name,
    b.status, b.type, b.inactive,
    b.units_gross, b.date, b.date_type, b.dcp_projectcompleted,
    b.date_filed, b.date_lastupdt, b.date_complete,
    b.portion_built_by_2025,
    b.portion_built_by_2035, b.portion_built_by_2055,
    a.geom
	FROM geom_merge a
	LEFT JOIN(
        SELECT DISTINCT ON (record_id) *
        FROM dcp_housing) AS b
	ON a.record_id = b.record_id
);
