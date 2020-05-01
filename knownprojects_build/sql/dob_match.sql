-- Create matches, containing inner spatial join of DOB and non-DOB given time constraint
-- Add KPDB-relevant DOB jobs to the combination of all other sources. This is called combined_dob
-- Get a list of relevant clusters. These clusters are the ones that contain overlap between DOB and non-DOB
-- Find cases where a DOB job matches with more than one non-DOB job, and flag for review.

drop table if exists dob_review;
with 
filtered_dcp_housing_proj as (
    SELECT a.source, 
        a.record_id::text, 
        a.record_name, 
        a.status, 
        a.type,
        a.inactive,
        a.units_gross::integer, 
        a.date, 
        a.date_type,
        a.date_filed,
        a.date_complete,  
        a.dcp_projectcompleted,
        null as portion_built_by_2025, 
        null as portion_built_by_2035, 
        null as portion_built_by_2055, 
        a.geom,
        b.units_prop
    from dcp_housing_proj a
    LEFT JOIN dcp_housing b
    ON a.record_id = b.job_number
    WHERE a.type <> 'Demolition'
    AND a.status <> 'Withdrawn'
    AND b.units_prop::int > 0
    AND (a.type <> 'Alteration'
        and a.units_gross::integer > 0)
),
matches as (
    SELECT 
    b.source, 
    b.record_id::text, 
    b.record_name, 
    b.status, 
    b.type,
    b.units_gross::integer, 
    b.date, 
    b.date_type,
    b.date_filed,
    b.date_complete,  
    b.dcp_projectcompleted,
    null as portion_built_by_2025, 
    null as portion_built_by_2035, 
    null as portion_built_by_2055,
    a.cluster_id,
    a.sub_cluster_id,
    null as review_initials,
    null as review_notes, 
    a.project_id, 
    null as units_net,
    b.inactive,
    b.geom
    FROM combined a
    INNER JOIN filtered_dcp_housing_proj b
    ON st_intersects(a.geom, b.geom)
    AND (case WHEN b.source = 'EDC Projected Projects' then TRUE 
        else (CASE
            WHEN b.date IS NOT NULL 
                then extract(year from b.date::timestamp) >= 
                    split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 2
            ELSE extract(year from b.date::timestamp) >= 2020 -2
            end)
        end)),
combined_dob as (
	select * 
	from matches
    union
    select *
	from combined),
relevantcluster as (
	select distinct project_id
	FROM matches),
multimatch as (
    select distinct record_id
    from matches
    where source = 'DOB'
    group by record_id
    having count(project_id) > 1),
multimatchcluster as (
    select distinct project_id
    from combined_dob
    where record_id in (select record_id from multimatch))
select *,
    (case when record_id in 
	 (select record_id from multimatch) and source='DOB' then 1 
        else 0 end) as dob_multimatch,
    (case when project_id in 
        (select project_id from multimatchcluster) then 1 else 0 end) as needs_review
	into dob_review
    from combined_dob
	where project_id in (
		select project_id 
		from relevantcluster)
	order by project_id;
