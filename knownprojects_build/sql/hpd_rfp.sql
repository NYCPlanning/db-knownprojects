/****************** Assign bbl geometries ****************/
ALTER TABLE hpd_rfp
    ADD source text,
    ADD project_id text,
    ADD project_name text,
    ADD project_status text,
    ADD project_type text,
    ADD number_of_units text,
    ADD portion_built_by_2025 text,
    ADD portion_built_by_2035 text,
    ADD portion_built_by_2055 text,
    ADD inactive text,
    ADD geom geometry(Polygon,4326);

-- Merge with Mappluto using bbl
UPDATE hpd_rfp a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE hpd_rfp t
SET source = 'HPD RFPs',
    project_id = request_for_proposals_name,
    project_name = request_for_proposals_name,
    project_status = (CASE 
			  	WHEN designated = 'Y' AND closed = 'Y' THEN 'RFP designated; financing closed'
			  	WHEN designated = 'Y' AND closed = 'N' THEN 'RFP designated; financing not closed'
			  	WHEN designated = 'N' AND closed = 'N' THEN 'RFP issued; financing not closed'
		END),
    project_type = NULL,
    number_of_units = (CASE WHEN est_units ~* '-' THEN NULL ELSE est_units END),
    portion_built_by_2025 = (CASE WHEN "likely_to_be_built_by_2025?" = 'Y' THEN 1 ELSE 0 END),
    portion_built_by_2035 = (CASE WHEN "likely_to_be_built_by_2025?" = 'Y' THEN 0 ELSE NULL END),
    portion_built_by_2055 = (CASE WHEN "likely_to_be_built_by_2025?" = 'Y' THEN 0 ELSE NULL END),
    inactive = NULL
    ;

/************************ Merging ***********************/
-- merge the records to project's level
DROP TABLE IF EXISTS hpd_rfp_proj;
CREATE TABLE hpd_rfp_proj AS(
	WITH geom_merge AS (
		SELECT project_name, ST_UNION(geom) AS geom
		FROM hpd_rfp
		GROUP BY project_name
	)
	SELECT b.source, b.project_id, b.project_name,
    b.project_status, b.project_type,b.inactive,
	b.number_of_units, b.portion_built_by_2025,
	b.portion_built_by_2035, b.portion_built_by_2055,
	a.geom
	FROM geom_merge a
	LEFT JOIN(
		SELECT DISTINCT ON (project_name) *
		FROM hpd_rfp) AS b
	ON a.project_name = b.project_name
);

