/****************** Assign bbl geometries ****************/
ALTER TABLE hpd_rfp
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
UPDATE hpd_rfp a
SET geom = b.wkb_geometry
FROM dcp_mappluto b
WHERE a.bbl = b.bbl::TEXT;

/********************* Column Mapping *******************/
UPDATE hpd_rfp t
SET source = 'HPD RFPs',
    record_id = md5(CAST((t.*)AS text)),
    record_name = request_for_proposals_name,
    status = (CASE 
			  	WHEN designated = 'Y' AND closed = 'Y' THEN 'RFP designated; financing closed'
			  	WHEN designated = 'Y' AND closed = 'N' THEN 'RFP designated; financing not closed'
			  	WHEN designated = 'N' AND closed = 'N' THEN 'RFP issued; financing not closed'
		END),
    type = NULL,
    units_gross = (CASE WHEN est_units ~* '-' THEN NULL 
                        ELSE REPLACE(est_units, ',', '') END),
    date = (CASE 
            WHEN closed_date = '-' THEN NULL 
            ELSE TO_CHAR(TO_DATE(closed_date, 'Mon-YY'), 'YYYY/MM') END),
    date_type = 'Month Closed',
    dcp_projectcompleted = NULL,
    date_filed = NULL,
    date_permittd = NULL,
    date_lastupdt = NULL,
    date_complete = NULL,
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
		SELECT record_name, ST_MAKEVALID(ST_UNION(geom)) AS geom
		FROM hpd_rfp
		GROUP BY record_name
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
		SELECT DISTINCT ON (record_name) *
		FROM hpd_rfp) AS b
	ON a.record_name = b.record_name
);

