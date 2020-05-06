WITH remaining_n_study AS(
SELECT NULL as project_id,
    source,
    record_id,
    record_name,
    status,
    type,
    units_gross,
    geom
FROM dcp_n_study_projected_proj
UNION
SELECT NULL as project_id,
    source,
    record_id,
    record_name,
    status,
    type,
    units_gross,
    geom
FROM dcp_n_study_future_proj),
max_proj as (
	SELECT max(SPLIT_PART(project_id, '-', 1)::integer) as max_proj_number
    FROM kpdb."2020"),
tmp as (
	SELECT
        (ROW_NUMBER() OVER (ORDER BY record_id) + b.max_proj_number)::text||'-1' as project_id,
		source,
        record_id,
        record_name,
        status,
        type,
        units_gross,
        units_gross as units_net,
        NULL as prop_within_5_years,
        NULL as prop_5_to_10_years,
        NULL as prop_after_10_years,
        NULL as within_5_years,
        NULL as from_5_to_10_years,
        NULL as after_10_years,
        NULL as phasing_rationale,
        NULL as phasing_assume_or_known,
        NULL as nycha,
        NULL as gq,
        NULL as senior_housing,
        NULL as assisted_living,
        NULL as inactive,
        geom
	from remaining_n_study a, max_proj b)
INSERT INTO kpdb."2020" (SELECT * FROM tmp 
		WHERE tmp.record_id NOT IN (SELECT DISTINCT record_id FROM kpdb."2020"));