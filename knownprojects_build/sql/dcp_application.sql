DROP TABLE if exists dcp_application;
with
cm_renewal as (
	select dcp_name as project_id
	from dcp_project
	where dcp_leadaction in (
		select dcp_projectactionid 
		from dcp_projectaction
		where dcp_name ~* 'CM')
	union 
	select split_part(dcp_dmsourceid, '_', 1) as project_id
	from dcp_projectaction
	where dcp_name ~* 'CM'
	union
	select dcp_name as project_id
	from dcp_project where dcp_projectid in (
	select dcp_project 
	from dcp_projectaction 
	where dcp_name ~* 'CM')),
--these are the projects that we are confident that are residential
school_seat_filter as (
	SELECT dcp_name
	FROM dcp_project
	WHERE dcp_sischoolseat is TRUE
	or regexp_replace(
		array_to_string(
			ARRAY[dcp_projectbrief,
				dcp_projectdescription,
				dcp_projectname], 
			' '),
		'[^a-zA-Z0-9]+', ' ','g'
		) like 'SS%'
	or regexp_replace(
		array_to_string(
			ARRAY[dcp_projectbrief,
				dcp_projectdescription,
				dcp_projectname], 
			' '),
		'[^a-zA-Z0-9]+', ' ','g'
		) ~* 'school seat|schools seat'
),
-- we exclude projects that have record closed, terminated or withdrawn as status
status_filter as (
	SELECT dcp_name
	FROM dcp_project
	WHERE statuscode ~* 'Record Closed|Terminated|Withdrawn'),
-- we exclude projects that have DCP as applicant type
applicant_filter as (
	SELECT dcp_name
	FROM dcp_project
	WHERE dcp_applicanttype = 'DCP'),
resid_units_filter as (
	SELECT dcp_name
	FROM dcp_project
	WHERE dcp_residentialsqft > 0
	or dcp_totalnoofdusinprojecd > 0
	or dcp_mihdushighernumber > 0
	or dcp_mihduslowernumber > 0
	or dcp_numberofnewdwellingunits > 0
	or dcp_noofvoluntaryaffordabledus >0),
--all projects that are after 2010, and NULLs included
year_filter as (
	SELECT dcp_name
	FROM dcp_project
	WHERE (extract(year FROM dcp_projectcompleted) >= 2010
	or extract(year FROM dcp_certifiedreferred) >= 2010
	or (dcp_projectcompleted is NULL and dcp_certifiedreferred is NULL))),
--all projects that have text pattern matched to be residential
text_filter as (
	SELECT dcp_name
	FROM dcp_project
	WHERE (regexp_replace(
		array_to_string(
			ARRAY[dcp_projectbrief,
				dcp_projectdescription,
				dcp_projectname], 
			' '),
		'[^a-zA-Z0-9]+', ' ','g'
		) like '%DUs%'
		or regexp_replace(
			array_to_string(
				ARRAY[dcp_projectbrief,
					dcp_projectdescription,
					dcp_projectname], 
				' '),
			'[^a-zA-Z0-9]+', ' ','g'
			) like '%MIH%'
		or regexp_replace(
			array_to_string(
				ARRAY[dcp_projectbrief,
					dcp_projectdescription,
					dcp_projectname], 
				' '),
			'[^a-zA-Z0-9]+', ' ','g'
		) ~* 
		array_to_string(ARRAY[
			'HUDSON YARDS',
			'home','family','resid',
			'appartment','apt','affordable', 
			'mix-','mixed-', 'dwelling',
			'living', 'housi'], '|')
	)
	AND regexp_replace(
		array_to_string(
			ARRAY[dcp_projectbrief,
				dcp_projectdescription,
				dcp_projectname],
			' '),
		'[^a-zA-Z0-9]+', ' ','g'
	) !~* 
		array_to_string(ARRAY[
		'RESIDENTIAL TO COMMERCIAL', 
		'SINGLE-FAMILY', 'SINGLE FAMILY', 
		'1-FAMILY', 'ONE FAMILY', 
		'ONE-FAMILY', '1 FAMILY',
		'FLOATING', 'TRANSITIONAL', 'FOSTER', 
		'ILLUMIN', 'RESIDENCE DISTRICT', 
		'LANDMARKS PRESERVATION COMMISSION',
		'EXISTING HOME', 'EXISTING HOUSE', 
		'NUMBER OF BEDS', 'EATING AND DRINKING', 
		'NO INCREASE', 'ENLARGEMENT', 'NON-RESIDENTIAL', 
		'LIVINGSTON', 'AMBULATORY', 
		'APPLICATION FOR PARKING',
		'CHAIRPERSON CERTIFICATION',
		'Chair Cert',
		'ROOFTOP'], '|')),
consolidated_filter as (
	SELECT dcp_name 
	FROM text_filter
	union
	SELECT dcp_name 
	FROM resid_units_filter),
relevant_projects as (
	SELECT distinct dcp_name 
	FROM consolidated_filter
	WHERE dcp_name in (SELECT dcp_name FROM year_filter)
	and dcp_name not in (SELECT dcp_name FROM school_seat_filter)
	and dcp_name not in (SELECT dcp_name FROM status_filter)
	and dcp_name not in (SELECT dcp_name FROM applicant_filter)
	UNION
	SELECT distinct project_id as dcp_name 
	FROM dcp_knownprojects 
	WHERE source = 'DCP Applications'
	and project_id in (SELECT dcp_name FROM year_filter)
	and project_id not in (SELECT dcp_name FROM school_seat_filter)
	and project_id not in (SELECT dcp_name FROM status_filter)
	and project_id not in (SELECT dcp_name FROM applicant_filter)),
zap_extract as (
	SELECT
	dcp_name,
	dcp_projectname,
	dcp_applicanttype,
	dcp_projectbrief,
	dcp_projectdescription,
	dcp_borough,
	statuscode,
	(CASE WHEN dcp_projectcompleted IS NULL THEN NULL
		ELSE TO_CHAR(dcp_projectcompleted, 'YYYY/MM/DD') END) 
		as projectcompleted,
	(CASE WHEN dcp_certifiedreferred IS NULL THEN NULL
		ELSE TO_CHAR(dcp_certifiedreferred, 'YYYY/MM/DD') END) 
		as certifiedreferred,
	COALESCE(dcp_totalnoofdusinprojecd, 0) as dcp_totalnoofdusinprojecd,
	COALESCE(dcp_mihdushighernumber, 0) as dcp_mihdushighernumber,
	COALESCE(dcp_mihduslowernumber, 0) as dcp_mihduslowernumber,
	COALESCE(dcp_numberofnewdwellingunits, 0) as dcp_numberofnewdwellingunits,
	COALESCE(dcp_noofvoluntaryaffordabledus, 0) as dcp_noofvoluntaryaffordabledus,
	COALESCE(dcp_residentialsqft, 0) as dcp_residentialsqft
	FROM dcp_project
	WHERE dcp_name in 
		(SELECT distinct dcp_name 
		FROM relevant_projects)),
text_renewal as (
	select dcp_name as project_id 
	from zap_extract
	where regexp_replace(
		array_to_string(
			ARRAY[dcp_projectbrief,
				dcp_projectdescription,
				dcp_projectname], 
			' '),
		'[^a-zA-Z0-9]+', ' ','g'
		) ~* 'renewal'
),
zap_geom as (
	SELECT a.*, b.wkb_geometry as geom 
	FROM zap_extract a
	left join dcp_knownprojects b 
	on (a.dcp_name = b.project_id)),
fill_missing_geom as (
	SELECT a.*, 
		(case when geom is NULL 
		then b.polygons else geom end) as geom1
	FROM zap_geom a
	left join project_geoms b
	on (a.dcp_name = b.projectid)),
get_ulurp as (
	SELECT a.*, b.dcp_ulurpnumber 
	FROM fill_missing_geom a
	left join dcp_projectaction b 
	on (a.dcp_name = b.dcp_project::text)),
get_ulurp_geom as (
	SELECT a.*, 
		(case when geom1 is NULL 
		then b.wkb_geometry else geom1 end) as geom2
	FROM get_ulurp a
	left join dcp_zoningmapamendments b
	on (a.dcp_ulurpnumber = b.ulurpno)) 
SELECT distinct 
--descriptor fields
	'DCP Application' as source,
	(case when dcp_name in (
		select project_id from cm_renewal
		union 
		select project_id from text_renewal) 
		then 1 else 0 end) as renewal,
	dcp_name as record_id,
	dcp_projectname as record_name,
	dcp_applicanttype, 
	dcp_projectbrief, 
	dcp_projectdescription,
	dcp_borough as borough,
	statuscode as status,

--units fields
	dcp_numberofnewdwellingunits,
	dcp_totalnoofdusinprojecd,
	dcp_mihdushighernumber,
	dcp_mihduslowernumber,
	dcp_noofvoluntaryaffordabledus,
	dcp_residentialsqft, 
	
--calculate units_gross
	COALESCE(
		nullif(dcp_numberofnewdwellingunits,0),
		nullif(dcp_totalnoofdusinprojecd,0),
		nullif(dcp_mihdushighernumber+ 
			dcp_noofvoluntaryaffordabledus,0),
		nullif(dcp_mihduslowernumber+ 
			dcp_noofvoluntaryaffordabledus,0))
	as units_gross,
	
--identify unit source
	COALESCE(
		(case when nullif(dcp_numberofnewdwellingunits,0) is not NULL 
			then 'dcp_numberofnewdwellingunits' end),
		(case when nullif(dcp_totalnoofdusinprojecd,0) is not NULL 
			then 'dcp_totalnoofdusinprojecd' end),
		(case when nullif(dcp_mihdushighernumber+dcp_noofvoluntaryaffordabledus,0) is not NULL 
			then 'dcp_mihdushighernumber + dcp_noofvoluntaryaffordabledus' end),
		(case when nullif(dcp_mihduslowernumber+ dcp_noofvoluntaryaffordabledus,0) is not NULL 
			then 'dcp_mihduslowernumber + dcp_noofvoluntaryaffordabledus' end)
		) 
	as units_gross_source,

--date fields
	certifiedreferred as date,	
	'Certified Referred' as date_type,
	projectcompleted as dcp_projectcompleted,

--dob fields
	NULL as date_filed,
	NULL as date_permittd, 
	NULL as date_lastupdt,
	NULL as date_complete,
	
--kpdb fields
	NULL as inactive, 
	NULL as type, 
	geom2 as geom
	INTO dcp_application
	FROM get_ulurp_geom;