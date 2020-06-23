INSERT INTO kpdb."2020" (source,
                                record_id,
                                record_name,
                                borough, 
                                units_gross,
                                prop_within_5_years,
                                prop_5_to_10_years,
                                prop_after_10_years,
                                phasing_rationale,
                                phasing_known,
                                nycha,
                                gq,
                                senior_housing,
                                assisted_living,
                                inactive,
                                project_id
                                )
SELECT 'DCP Planner-Added Projects' as source,
        record_id,
        record_name,
        borough, 
        units_gross,
        prop_within_5_years,
        prop_5_to_10_years,
        prop_after_10_years,
        phasing_rationale,
        phasing_known,
        nycha,
        gq,
        senior_housing,
        assisted_living,
        inactive,
        project_id FROM dcp_planneradded.latest
WHERE record_id NOT IN (SELECT DISTINCT record_id FROM kpdb."2020")
AND omit IS NULL;

-- Assign stand-alone project IDs for new additions
WITH
max_proj AS (
	SELECT max(LTRIM(split_part(project_id, '-', 1), 'p')::integer) AS max_proj_number
    FROM kpdb."2020"),
tmp AS (
	SELECT
        a.source,
        a.record_id,
		a.record_name,
        'p'||(ROW_NUMBER() OVER (ORDER BY record_id) + b.max_proj_number)::text||'-1' as project_id
    FROM kpdb."2020" a, max_proj b
    WHERE a.project_id IS NULL)
UPDATE kpdb."2020" a
	SET project_id = b.project_id
	FROM tmp b
	WHERE a.source = b.source
	AND a.record_id::text = b.record_id::text
	AND a.record_name::text = b.record_name::text;