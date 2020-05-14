-- Add previously filtered DOB based on kpdb_corrections
INSERT INTO kpdb."2020"
(SELECT	NULL as project_id,
        record_id,
		record_name,
        NULL as borough,
        status,
        type,
        date,
        date_type,
        units_gross,
        coalesce(units_net::integer, units_gross::integer) as units_net,
        NULL as prop_within_5_years,
        NULL as prop_5_to_10_years,
        NULL as prop_after_10_years,
        NULL as within_5_years,
        NULL as from_5_to_10_years,
        NULL as after_10_years,
        NULL as phasing_rationale,
        NULL as phasing_known,
        NULL as nycha,
        NULL as gq,
        NULL as senior_housing,
        NULL as assisted_living,
        inactive,
        geom
    FROM dcp_housing_proj
    WHERE record_id IN (SELECT DISTINCT record_id
                        FROM kpdb_corrections
                        WHERE field = 'add')
    AND record_id NOT IN (SELECT DISTINCT record_id
                        FROM kpdb."2020"));

-- Add previously filtered ZAP based on kpdb_corrections


-- Assign stand-alone project IDs for new additions
WITH
max_proj AS (
	SELECT max(split_part(project_id, '-', 1)::integer) AS max_proj_number
    FROM kpdb."2020"),
tmp AS (
	SELECT
        a.source,
        a.record_id,
		a.record_name,
        (ROW_NUMBER() OVER (ORDER BY record_id) + b.max_proj_number)::text||'-1' as project_id
    FROM kpdb."2020" a, max_proj b
    WHERE a.project_id IS NULL)
UPDATE kpdb_gross."2020" a
	SET project_id = b.project_id,
	FROM tmp b
	WHERE a.source = b.source
	AND a.record_id = b.record_id
	AND a.record_name = b.record_name;