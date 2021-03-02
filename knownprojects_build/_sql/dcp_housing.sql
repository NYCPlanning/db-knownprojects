DROP TABLE IF EXISTS dcp_housing_poly;
WITH 
-- Prior to geom steps, filter to relevant DOB jobs
dcp_housing_filtered AS (
	SELECT *
    FROM dcp_housing a
    WHERE job_type <> 'Demolition'
    AND a.job_status <> '9. Withdrawn'
    AND a.classa_net::integer <> 0
    AND a.classa_prop::integer > 0
    AND NOT (a.job_type = 'Alteration'
        AND a.classa_net::integer <= 0)
),
/*Join with mappluto on BBL to get polygon geom. 
Mappluto has invalid geoms, so some are fixed.
*/
bbl_join AS (
	SELECT 
		a.job_number,
		a.bbl,
		a.wkb_geometry as point_geom,
		(CASE
			WHEN ST_IsValid(b.wkb_geometry) THEN b.wkb_geometry
			ELSE ST_MakeValid(b.wkb_geometry) 
		END) as bbl_join_geom
	FROM dcp_housing_filtered a
	LEFT JOIN dcp_mappluto b
    ON a.bbl = b.bbl::bigint::text
),
/* Spatial join with mappluto to get polygon geom where bbl geom failed
This happens as a separate step to limit the number of records needing
a spatial join. Mappluto has invalid geoms, so some are fixed. */
spatial_join AS(
	SELECT 
		a.job_number,
		a.bbl,
		a.point_geom,
		(CASE
			WHEN ST_IsValid(b.wkb_geometry) THEN b.wkb_geometry
			ELSE ST_MakeValid(b.wkb_geometry) 
		END) as spatial_join_geom
	FROM bbl_join a
	JOIN dcp_mappluto b
	ON ST_Within(a.point_geom, ST_MakeValid(b.wkb_geometry))
	WHERE a.bbl_join_geom IS NULL AND a.point_geom IS NOT NULL
),
-- Combine into a single geom lookup
_geom AS (
	SELECT a.job_number,
		a.bbl,
		(CASE
			WHEN a.bbl_join_geom IS NULL THEN b.spatial_join_geom
			ELSE a.bbl_join_geom
		END) as geom,
		(CASE
			WHEN a.bbl_join_geom IS NULL THEN 'Spatial'
			ELSE 'BBL'
		END) as geom_source
	FROM bbl_join a
	LEFT JOIN spatial_join b
	ON a.job_number = b.job_number
)

SELECT 
	'DOB' as source,
	a.job_number as record_id,
	NULL as record_id_input,
	a.address as record_name,
	'DOB: '||a.job_status as status,
	a.job_type as type,
	a.classa_net as units_net,
	(CASE
	    WHEN a.date_permittd LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_permittd, 'YYYY-MM-DD'), 'YYYY/MM/DD')
	    ELSE NULL
	END) as date,
	'Date Permitted' as date_type,
	(CASE
	    WHEN a.date_filed LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_filed, 'YYYY-MM-DD'), 'YYYY/MM/DD')
	    ELSE NULL
	END) as date_filed,
	(CASE
	    WHEN a.date_lastupdt LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_lastupdt, 'YYYY-MM-DD'), 'YYYY/MM/DD')
	    ELSE NULL
	END) as date_lastupdt,
	(CASE
	    WHEN a.date_complete LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_complete, 'YYYY-MM-DD'), 'YYYY/MM/DD')
	    ELSE NULL
	END) as date_complete,
	(CASE WHEN a.job_inactive = 'Inactive' THEN 1 ELSE 0 END) as inactive,

    -- Phasing
    (CASE 
        WHEN a.job_status ~* '1|2|3' AND inactive <> '1' THEN 1 
        ELSE NULL
    END) as prop_within_5_years,
    (CASE 
        WHEN a.job_status <> '9. Withdrawn' AND inactive = '1' THEN 1 
        ELSE NULL
    END) as prop_5_to_10_years,
    NULL as prop_after_10_years,
    0 as phasing_known,
	b.geom,
	b.geom_source
INTO dcp_housing_poly
FROM dcp_housing_filtered a
JOIN _geom b
ON a.job_number = b.job_number;