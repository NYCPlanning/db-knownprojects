/*
DESCRIPTION:
    Identies dcp_housing records that spatially overlap with 
    and are within a few years of non-DOB records.
INPUTS: 
    _combined
    dcp_housing_poly
OUTPUTS: 
    dob_review
*/
DROP TABLE IF EXISTS dob_review;
WITH 
-- Join project_record_ids to the combined source data
projects AS (
	SELECT
		b.project_record_ids,
		a.*
	FROM _combined a
	INNER JOIN _project_record_ids b
ON a.record_id=any(b.project_record_ids)),
/* 
Identify records that intersect with DOB jobs. This excludes records from EDC 
Projected Projects, and has a time constraint. Need to review how this
constraint gets updated this year.
*/
matches as (
    SELECT 
    	b.*,
    	a.record_id as match_record_id,
    	a.record_id_input as match_record_id_input,
    	a.project_record_ids
    FROM projects a
    INNER JOIN _combined b
    ON st_intersects(a.geom, b.geom)
    AND (CASE 
    		WHEN b.source = 'EDC Projected Projects' THEN TRUE 
        	ELSE (CASE
            	WHEN b.date IS NOT NULL 
                	THEN extract(year from b.date::timestamp) >= 
                    split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 2
            	ELSE extract(year from b.date::timestamp) >= 2020 -2
            END)
        END)
    WHERE b.source = 'DOB'
    AND a.geom IS NOT NULL 
    AND b.geom IS NOT NULL
),
-- Find cases where a DOB job matched with more than one project
multimatch AS (
    SELECT DISTINCT record_id
    FROM matches
    GROUP BY record_id
    HAVING count(DISTINCT(project_record_ids)) > 1
),
/* 
Find all projects where a DOB job matched with it, and that
DOB job matched with more than one project.
*/
multimatchproject as (
    SELECT project_record_ids
    FROM matches
    WHERE record_id IN (SELECT record_id FROM multimatch)
),
-- Combine matched DOB records with records from project table 
combined_dob as (
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
		project_record_ids,
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
		project_record_ids,
		geom
	FROM projects)
-- Assign flags for review and append contextual DOB date and unit information
SELECT a.*,
		b.classa_init,
		b.classa_prop,
		b.otherb_init,
		b.otherb_prop,
		b.date_filed,
		b.date_lastupdt,
		b.date_complete,
	    (CASE 
	    	WHEN a.record_id IN (SELECT record_id FROM multimatch) AND a.source='DOB' THEN 1 
	        ELSE 0
	     END) as dob_multimatch,
	    (CASE 
	    	WHEN a.project_record_ids IN (SELECT project_record_ids FROM multimatchproject) THEN 1 
	    	ELSE 0 
	    END) as project_has_dob_multi
INTO dob_review
FROM combined_dob a
LEFT JOIN dcp_housing_poly b
ON a.record_id = b.record_id
-- Only output matched DOB jobs and the records associated with them for review
WHERE a.record_id IN (SELECT record_id FROM matches) 
OR a.record_id IN (SELECT UNNEST(project_record_ids) FROM matches)
ORDER BY project_record_ids;
