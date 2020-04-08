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
    select project_id
    from combined_dob
    where source = 'DOB'
    group by project_id
    having count(*) > 1),
multimatchcluster as (
	select distinct cluster_id
	from combined_dob 
	where project_id in (
		select project_id 
		from multimatch))
select *,
    (case when cluster_id in 
	 (select cluster_id from multimatchcluster) then 1 
        else 0 end) as review_flag
    into dob_review
	from combined_dob
	where cluster_id in (
		select cluster_id 
		from relevantcluster)
	order by cluster_id, sub_cluster_id;