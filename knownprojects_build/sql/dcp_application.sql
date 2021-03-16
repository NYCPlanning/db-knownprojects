/*
DESCRIPTION:
	

INPUTS:
	dcp_projects
	dcp_projectactions
    dcp_project_bbls
    dcp_mappluto_wi
    dcp_knownprojects
    corrections_main
    DEPRECATING: kpdb_<last_version>.dcp_project
OUTPUTS: 
	dcp_application
*/
DROP TABLE IF EXISTS dcp_application;
WITH 
zap_translated as (
	SELECT
	    dcp_name,
	    dcp_projectname,
	    dcp_projectbrief,
	    dcp_projectdescription,
	    (CASE 
	    	WHEN dcp_applicanttype::numeric = 717170000 THEN 'DCP'
	    	WHEN dcp_applicanttype::numeric = 717170001 THEN 'Other Public Agency'
	    	WHEN dcp_applicanttype::numeric = 717170002 THEN 'Private'
	    END) as dcp_applicanttype,
	    (CASE
	    	WHEN dcp_visibility::numeric = 717170002 THEN 'Applicant Only'
	    	WHEN dcp_visibility::numeric = 717170001 THEN 'CPC Only'
	    	WHEN dcp_visibility::numeric = 717170003 THEN 'General Public'
	    	WHEN dcp_visibility::numeric = 717170000 THEN 'Internal DCP Only'
	    	WHEN dcp_visibility::numeric = 717170004 THEN 'LUP'

	    END) as dcp_visibility,
	    (CASE 
	    	WHEN dcp_borough::numeric = 717170000 then 'Bronx'
	    	WHEN dcp_borough::numeric = 717170002 then 'Brooklyn'
	    	WHEN dcp_borough::numeric = 717170001 then 'Manhattan'
	    	WHEN dcp_borough::numeric = 717170004 then 'Staten Island'
	    	WHEN dcp_borough::numeric = 717170005 then 'Citywide'
	    	WHEN dcp_borough::numeric = 717170003 then 'Queens'
	    END) as dcp_borough,
	    (CASE 
	    	WHEN statuscode::numeric = 1 THEN 'Active'
	    	WHEN statuscode::numeric = 717170000 THEN 'On-Hold'
	    	WHEN statuscode::numeric = 707070003 THEN 'Record Closed'
	    	WHEN statuscode::numeric = 707070000 THEN 'Complete'
	    	WHEN statuscode::numeric = 707070002 THEN 'Terminated'
	    	WHEN statuscode::numeric = 707070001 THEN 'Withdrawn-Applicant Unresponsive'
	    	WHEN statuscode::numeric = 717170001 THEN 'Withdrawn-Other'

	    END) as statuscode,
	    (CASE 
	    	WHEN dcp_publicstatus::numeric = 717170000 THEN 'Filed'
	    	WHEN dcp_publicstatus::numeric = 717170001 THEN 'In Public Review'
	    	WHEN dcp_publicstatus::numeric = 717170002 THEN 'Completed'
	    	WHEN dcp_publicstatus::numeric = 717170005 THEN 'Noticed'
	    END) as dcp_publicstatus,
        (CASE 
            WHEN dcp_projectphase::numeric = 717170000 THEN 'Study'
	    	WHEN dcp_projectphase::numeric = 717170001 THEN 'Pre-Pas'
	    	WHEN dcp_projectphase::numeric = 717170002 THEN 'Pre-Cert'
            WHEN dcp_projectphase::numeric = 717170003 THEN 'Public Review'
            WHEN dcp_projectphase::numeric = 717170004 THEN 'Public Completed'
	    	WHEN dcp_projectphase::numeric = 717170005 THEN 'Initiation'
        END) as dcp_projectphase,
	    (CASE WHEN dcp_projectcompleted IS NULL THEN NULL
	        ELSE TO_CHAR(dcp_projectcompleted::timestamp, 'YYYY/MM/DD') 
	    END)  as dcp_projectcompleted,
	    (CASE WHEN dcp_certifiedreferred IS NULL THEN NULL
	        ELSE TO_CHAR(dcp_certifiedreferred::timestamp, 'YYYY/MM/DD') 
	    END) as dcp_certifiedreferred,
	    COALESCE(dcp_totalnoofdusinprojecd::numeric, 0) as dcp_totalnoofdusinprojecd,
	    COALESCE(dcp_mihdushighernumber::numeric, 0) as dcp_mihdushighernumber,
	    COALESCE(dcp_mihduslowernumber::numeric, 0) as dcp_mihduslowernumber,
	    COALESCE(dcp_numberofnewdwellingunits::numeric, 0) as dcp_numberofnewdwellingunits,
	    COALESCE(dcp_noofvoluntaryaffordabledus::numeric, 0) as dcp_noofvoluntaryaffordabledus,
	    COALESCE(dcp_residentialsqft::numeric, 0) as dcp_residentialsqft
	FROM dcp_projects
),
cm_renewal as (
	select dcp_name as project_id 
	from dcp_projects
	where _dcp_leadaction_value in (
	select dcp_projectactionid 
	from dcp_projectactions
	where dcp_name ~* 'CM')
	
	UNION
	select split_part(dcp_dmsourceid, '_', 1) as project_id
	from dcp_projectactions
	where dcp_name ~* 'CM' and dcp_dmsourceid is not null
	
	UNION
	select dcp_name as project_id 
	from dcp_projects where dcp_projectid in (
	select _dcp_project_value from dcp_projectactions
	where dcp_name ~* 'CM')
),
text_renewal as (
    select dcp_name as project_id 
    from dcp_projects
    where regexp_replace(
        array_to_string(
            ARRAY[dcp_projectbrief,
                dcp_projectdescription,
                dcp_projectname], 
            ' '),
        '[^a-zA-Z0-9]+', ' ','g'
        ) ~* 'renewal'
),
school_seat_filter as (
    SELECT dcp_name
    FROM dcp_projects
    WHERE dcp_sischoolseat::boolean is TRUE
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
    FROM zap_translated
    WHERE statuscode ~* 'Record Closed|Terminated|Withdrawn'
),

resid_units_filter as (
    SELECT dcp_name
    FROM zap_translated
    WHERE dcp_residentialsqft > 0
    or dcp_totalnoofdusinprojecd > 0
    or dcp_mihdushighernumber > 0
    or dcp_mihduslowernumber > 0
    or dcp_numberofnewdwellingunits > 0
    or dcp_noofvoluntaryaffordabledus >0
),

--all projects that are after 2010, and NULLs included
year_filter as (
    SELECT dcp_name
    FROM zap_translated
    WHERE (extract(year FROM dcp_projectcompleted::date) >= 2010
    or extract(year FROM dcp_certifiedreferred::date) >= 2010
    or (dcp_projectcompleted is NULL and dcp_certifiedreferred is NULL))
),

--all projects that have text pattern matched to be residential
text_filter as (
    SELECT dcp_name
    FROM dcp_projects
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
        'ROOFTOP'], '|')
),
consolidated_filter as (
    SELECT dcp_name 
    FROM text_filter
    union
    SELECT dcp_name 
    FROM resid_units_filter
),
applicanttype_filter as (
	SELECT dcp_name 
	FROM zap_translated
	WHERE dcp_applicanttype = 'DCP'
),
records_last_kpdb as (
	SELECT record_id 
	FROM dcp_knownprojects
	WHERE source = 'DCP Application'
),
-- records_last_dcp_project as (
-- 	SELECT dcp_name as record_id
-- 	FROM kpdb_2020.dcp_project
-- ),
records_corr_remove as (
	SELECT record_id 
	FROM corrections_main
	WHERE field = 'remove'
),
records_corr_add as (
	SELECT record_id 
	FROM corrections_main
	WHERE field = 'add'
),
relevant_projects as (
    SELECT distinct dcp_name 
    FROM consolidated_filter
    WHERE (
        dcp_name in (SELECT dcp_name FROM year_filter) OR 
        dcp_name in (SELECT record_id FROM records_corr_add)
    )
    and dcp_name not in (SELECT dcp_name FROM school_seat_filter)
    and dcp_name not in (SELECT dcp_name FROM status_filter)
    and dcp_name not in (SELECT dcp_name FROM applicanttype_filter)
    and dcp_name not in (SELECT record_id FROM records_corr_remove)
),
_dcp_application as (
    SELECT distinct 
	--descriptor fields
    'DCP Application' as source,
    (case when dcp_name in (
        select project_id from cm_renewal
        union 
        select project_id from text_renewal) 
        then 1 else 0 end) as renewal,
    (CASE WHEN dcp_name in (
    	select distinct dcp_name 
    	from relevant_projects) then 1
    	else 0 end) as flag_relevant,
    (CASE WHEN dcp_name in (
    	select distinct dcp_name 
    	from year_filter) then 1
    	else 0 end) as flag_year,
    (CASE WHEN dcp_name in (
    	select distinct dcp_name 
    	from school_seat_filter) then 1
    	else 0 end) as flag_school_seat,
    (CASE WHEN dcp_name in (
    	select distinct dcp_name 
    	from text_filter) then 1
    	else 0 end) as flag_resid_text,
    (CASE WHEN dcp_name in (select record_id from records_last_kpdb)
    	 THEN 1 ELSE 0 END) as flag_in_last_kpdb,
	(CASE WHEN dcp_name not in (select record_id from records_last_kpdb) 
		THEN 1 ELSE 0 END) as flag_not_in_last_kpdb,
	(CASE 
		WHEN dcp_name in (select record_id from records_corr_remove) THEN 'remove' 
		WHEN dcp_name in (select record_id from records_corr_add) THEN 'add' 
	END) as flag_corrected,
	-- (CASE WHEN dcp_name not in (select record_id from records_last_dcp_project) 
	-- 	THEN 1 ELSE 0 END) as flag_new_in_zap,
    dcp_name as record_id,
    dcp_projectname as record_name,
    dcp_projectbrief, 
    dcp_projectdescription,
    dcp_borough as borough,
    statuscode,
    (case
		when dcp_projectphase ~* 'project completed' then 'DCP 4: Zoning Implemented'
		when dcp_projectphase ~* 'pre-pas|pre-cert' then 'DCP 2: Application in progress'
		when dcp_projectphase ~* 'initiation' then 'DCP 1: Expression of interest'
		when dcp_projectphase ~* 'public review' then 'DCP 3: Certified/Referred'
	end) as status,
    dcp_publicstatus as publicstatus,
    dcp_certifiedreferred,
    dcp_applicanttype as applicanttype,
    dcp_visibility as visibility,
    
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
            dcp_noofvoluntaryaffordabledus,0)
    )::numeric as units_gross,
    
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
    AS units_gross_source
    FROM zap_translated
), 
-- Assigning Geometry Using BBL
geom_pluto as (
	SELECT
		a.record_id,
		ST_Union(b.wkb_geometry) as geom
	FROM(
		SELECT 
			a.record_id,
			b.dcp_bblnumber as bbl
		from _dcp_application a
		LEFT JOIN dcp_projectbbls b
		ON a.record_id = trim(split_part(b.dcp_name, '-', 1))
	) a LEFT JOIN dcp_mappluto_wi b
	ON a.bbl::numeric = b.bbl::numeric
	GROUP BY a.record_id
),
-- Assigning Geometry Using Previous version of KPDB
geom_kpdb as (
	SELECT 
		a.record_id,
		nullif(a.geom, b.the_geom) as geom
	FROM geom_pluto a
	LEFT JOIN dcp_knownprojects b
	ON a.record_id = b.record_id
),
-- Assigning Geometry Using Zoning Map Amendments
geom_ulurp as (
SELECT 
	a.record_id,
	nullif(a.geom, st_union(b.wkb_geometry)) as geom
FROM(
	select 
		a.record_id,
		a.geom,
		b.dcp_ulurpnumber
	FROM (
		select
			a.record_id,
			a.geom,
			b.dcp_projectid
		from geom_kpdb a
		LEFT JOIN dcp_projects b
		on a.record_id = b.dcp_name
	) a LEFT JOIN dcp_projectactions b
	ON a.dcp_projectid = b._dcp_project_value
) a LEFT JOIN dcp_zoningmapamendments b
ON a.dcp_ulurpnumber = b.ulurpno
GROUP BY a.record_id, a.geom
)
-- ain table with the geometry lookup
SELECT a.*, b.geom
INTO dcp_application
FROM _dcp_application a
LEFT JOIN geom_ulurp b 
ON a.record_id = b.record_id;