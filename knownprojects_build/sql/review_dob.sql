/*
DESCRIPTION:
    Identies dcp_housing records that spatially overlap with 
    and are within a few years of non-DOB records.
INPUTS: 
    combined
    dcp_housing_poly
OUTPUTS: 
    _review_dob
*/
DROP TABLE IF EXISTS _review_dob;
WITH 
projects AS (
	SELECT
		b.project_record_ids,
		b.project_id,
		a.*
	FROM combined a
	INNER JOIN (
		SELECT 
			unnest(project_record_ids) as record_id,
			project_record_ids,
			ROW_NUMBER() OVER(ORDER BY project_record_ids) as project_id
		FROM _project_record_ids
	) b ON a.record_id=b.record_id
),
matches AS (
	/* 
	Identify records that intersect with DOB jobs. This excludes records from EDC 
	Projected Projects, and has a time constraint. Need to review how this
	constraint gets updated this year.
	*/
    SELECT 
    	b.*,
    	a.record_id as match_record_id,
    	a.record_id_input as match_record_id_input,
    	a.project_record_ids,
		a.project_id
    FROM projects a
    INNER JOIN combined b
    ON st_intersects(a.geom, b.geom)
    AND (CASE 
    		WHEN b.source = 'EDC Projected Projects' THEN TRUE 
        	ELSE (CASE
            	WHEN b.date IS NOT NULL 
                	THEN extract(year from b.date::timestamp) >= 
                    split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 2
            	ELSE extract(year from b.date::timestamp) >= extract(year from CURRENT_DATE) - 2
            END)
        END)
    WHERE b.source = 'DOB'
    AND a.geom IS NOT NULL 
    AND b.geom IS NOT NULL
),
combined_dob as (
	-- Combine matched DOB records with records from project table 
	SELECT
		source,
		record_id,
		record_name,
		status,
		type,
		units_gross,
		date,
		date_type,
		inactive,
		no_classa,
		project_record_ids,
		project_id,
		geom
	FROM matches
    UNION
    SELECT 
    	source,
		record_id,
		record_name,
		status,
		type,
		units_gross,
		date,
		date_type,
		inactive,
		no_classa,
		project_record_ids,
		project_id,
		geom
	FROM projects
),
-- Find cases where a DOB job matched with more than one project
multimatch AS (
	SELECT record_id FROM matches GROUP BY record_id
    HAVING count(DISTINCT(project_id))>1
),
/*
Find all projects where a DOB job matched with it, and that
DOB job matched with more than one project.
*/
multimatchproject as (
    SELECT project_id
    FROM matches
    WHERE record_id IN (SELECT record_id FROM multimatch)
)
-- Assign flags for review and append contextual DOB date and unit information
SELECT 
	a.source,
	a.record_id,
	a.record_name,
	a.status,
	a.type,
	a.units_gross,
	a.date,
	a.date_type,
	a.inactive,
	a.no_classa,
	a.project_record_ids,
	b.classa_init,
	b.classa_prop,
	b.otherb_init,
	b.otherb_prop,
	b.date_filed,
	b.date_lastupdt,
	b.date_complete,
	(a.record_id IN (SELECT record_id FROM multimatch) AND a.source='DOB')::integer as dob_multimatch,
	(a.project_id IN (SELECT project_id FROM multimatchproject))::integer as project_has_dob_multi,
	(a.geom IS NULL)::integer as no_geom,
	a.geom
INTO _review_dob
FROM combined_dob a
LEFT JOIN dcp_housing_poly b
ON a.record_id = b.record_id
-- Only output matched DOB jobs and the records associated with them for review
WHERE a.record_id IN (
	SELECT record_id FROM matches 
	UNION SELECT UNNEST(project_record_ids) FROM matches
)
ORDER BY array_to_string(project_record_ids, ',');