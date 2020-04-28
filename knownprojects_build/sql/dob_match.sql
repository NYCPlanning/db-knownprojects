-- Create matches, containing inner spatial join of DOB and non-DOB given time constraint
-- Add KPDB-relevant DOB jobs to the combination of all other sources. This is called combined_dob
-- Get a list of relevant clusters. These clusters are the ones that contain overlap between DOB and non-DOB
-- Find cases where a DOB job matches with more than one non-DOB job, and flag for review.

drop table if exists dob_review;
with 
filtered_dcp_housing_proj as (
    SELECT a.source, 
        a.project_id::text, 
        a.project_name, 
        a.project_status, 
        a.project_type,
        a.inactive,
        a.number_of_units::integer, 
        a.date, 
        a.date_type,
        a.date_permittd,
        a.date_complete,  
        a.dcp_projectcompleted,
        null as portion_built_by_2025, 
        null as portion_built_by_2035, 
        null as portion_built_by_2055, 
        a.geom,
        b.units_prop
    from dcp_housing_proj a
    LEFT JOIN dcp_housing b
    ON a.project_id = b.job_number
    WHERE a.project_type <> 'Demolition'
    AND a.project_status <> 'Withdrawn'
    AND b.units_prop::int > 0
),
matches as (
    SELECT 
    b.source, 
    b.project_id::text, 
    b.project_name, 
    b.project_status, 
    b.project_type,
    b.number_of_units::integer, 
    b.date, 
    b.date_type,
    b.date_permittd,
    b.date_complete,  
    b.dcp_projectcompleted,
    null as portion_built_by_2025, 
    null as portion_built_by_2035, 
    null as portion_built_by_2055,
    a.cluster_id,
    a.sub_cluster_id,
    a.review_initials,
    a.review_notes, 
    a.development_id, 
    null as adjusted_units,
    b.inactive,
    b.geom
    FROM combined a
    INNER JOIN filtered_dcp_housing_proj b
    ON st_intersects(a.geom, b.geom)
    AND split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 1 < extract(year from b.date::timestamp)),
combined_dob as (
	select * 
	from matches
    union
    select *
	from combined),
relevantcluster as (
	select distinct development_id
	FROM matches),
multimatch as (
    select distinct project_id
    from matches
    where source = 'DOB'
    group by project_id
    having count(development_id) > 1),
multimatchcluster as (
    select distinct development_id
    from combined_dob
    where project_id in (select project_id from multimatch)
)
select *,
    (case when project_id in 
	 (select project_id from multimatch) and source='DOB' then 1 
        else 0 end) as dob_multimatch,
    (case when development_id in 
        (select development_id from multimatchcluster) then 1 else 0 end) as needs_review
	into dob_review
    from combined_dob
	where development_id in (
		select development_id 
		from relevantcluster)
	order by development_id;
