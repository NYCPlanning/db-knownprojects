-- Create matches, containing inner spatial join of DOB and non-DOB given time constraint
-- Add KPDB-relevant DOB jobs to the combination of all other sources. This is called combined_dob
-- Get a list of relevant clusters. These clusters are the ones that contain overlap between DOB and non-DOB
-- Find cases where a DOB job matches with more than one non-DOB job, and flag for review.

drop table if exists dob_review;
with matches as (
    SELECT 
    b.source, 
    b.project_id::text, 
    b.project_name, 
    b.project_status, 
    b.project_type,
    b.number_of_units::integer, 
    b.date, 
    b.date_type, 
    b.dcp_projectcompleted, 
    null as portion_built_by_2025, 
    null as portion_built_by_2035, 
    null as portion_built_by_2055, 
    a.cluster_id, 
    a.sub_cluster_id, 
    null as adjusted_units,
    b.inactive,
    b.geom
    FROM combined a
    INNER JOIN dcp_housing b
    ON st_intersects(a.geom, b.geom)
    AND split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 1 < extract(year from b.date::timestamp)),
combined_dob as (
	select * 
	from matches
    union
    select *
	from combined),
relevantcluster as (
	select distinct cluster_id
	FROM matches),
multimatch as (
    select distinct project_id
    from matches
    where source = 'DOB'
    group by project_id
    having count(cluster_id) > 1)
select *,
    (case when project_id in 
	 (select project_id from multimatch) and source='DOB' then 1 
        else 0 end) as review_flag
	into dob_review
    from combined_dob
	where cluster_id in (
		select cluster_id 
		from relevantcluster)
	order by cluster_id, sub_cluster_id;