-- Add previously filtered DOB based on kpdb_corrections
INSERT INTO kpdb."2020"
(SELECT	NULL as project_id,
	    'DOB' as source,
        record_id,
		record_name,
        NULL as borough,
        status,
        type,
        date,
        date_type,
        units_gross,
        units_gross as units_net,
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
                        FROM kpdb_corrections.latest
                        WHERE field = 'add')
    AND record_id NOT IN (SELECT DISTINCT record_id
                        FROM kpdb."2020"));

-- Add previously filtered ZAP based on kpdb_corrections
with 
record_to_add as (
	select distinct record_id 
	from kpdb_corrections.latest
	where field = 'add'
	and record_id not in (select record_id from kpdb."2020")),
zap_geom as (
	SELECT b.project_id as record_id, b.wkb_geometry as geom 
	FROM dcp_knownprojects b 
	WHERE b.project_id in (select record_id from record_to_add)),
fill_missing_geom as (
	SELECT b.projectid as record_id, b.polygons as geom
	FROM project_geoms b
	where b.projectid in (select record_id from record_to_add)
	and b.projectid not in (select record_id from zap_geom)),
geometry as (
	select * from zap_geom UNION
	select * from fill_missing_geom),
new_zap as (
	select distinct
	NULL as project_id,
	'DCP Application' as source,
	dcp_name as record_id,
	dcp_projectname as record_name,
	dcp_borough as borough,
	statuscode as status,
	null as type,
	dcp_certifiedreferred::text as date,	
	'Certified Referred' as date_type,
	COALESCE(
    nullif(COALESCE(dcp_totalnoofdusinprojecd, 0),0),
    nullif(COALESCE(dcp_totalnoofdusinprojecd, 0),0),
    nullif(COALESCE(dcp_mihdushighernumber, 0)+ 
        COALESCE(dcp_noofvoluntaryaffordabledus, 0),0),
    nullif(COALESCE(dcp_mihduslowernumber, 0)+ 
        COALESCE(dcp_noofvoluntaryaffordabledus, 0),0))::text
    as units_gross,
	null as units_net,
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
	NULL as inactive
	FROM dcp_project a
	where dcp_name in (select record_id from record_to_add))
INSERT INTO kpdb."2020"
select a.*, b.geom as geom 
from new_zap a
left join geometry b
on (a.record_id = b.record_id);

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
