DROP TABLE if exists dcp_application;
With dcp_project_filtered as (
		SELECT dcp_projectid,dcp_name, dcp_projectcompleted,dcp_certifiedreferred,dcp_residentialsqft,statuscode,dcp_applicanttype,
				dcp_projectbrief, dcp_projectdescription, dcp_projectname, dcp_borough, dcp_numberofnewdwellingunits
		FROM dcp_project
		WHERE  (dcp_name ~* 'P2005M0053|P2009M0294|P2014M0257' or dcp_name !~* 'P2016Q0238|P2016R0149|P2012M0255')
		AND (extract(year from dcp_projectcompleted) >= 2012 or extract(year from dcp_certifiedreferred) >= 2012)
		AND statuscode !~* 'Record Closed|Terminated|Withdrawn'
		AND dcp_applicanttype != 'DCP'
		AND dcp_projectbrief||dcp_projectdescription||dcp_projectname ~*'home|family|resid|appartment|apt|affordable|dwell|living|housi|mih|DUs'
		AND dcp_projectbrief||dcp_projectdescription||dcp_projectname !~*'RESIDENTIAL TO COMMERCIAL|SINGLE-FAMILY|SINGLE FAMILY|1-FAMILY|ONE FAMILY|ONE-FAMILY|1 FAMILY'
		AND dcp_projectbrief||dcp_projectdescription||dcp_projectname !~*'FLOATING|TRANSITIONAL|FOSTER|ILLUMIN|RESIDENCE DISTRICT|LANDMARKS PRESERVATION COMMISSION'
		AND dcp_projectbrief||dcp_projectdescription||dcp_projectname !~*'EXISTING HOME|EXISTING HOUSE|NUMBER OF BEDS|EATING AND DRINKING|NO INCREASE|ENLARGEMENT|NON-RESIDENTIAL|LIVINGSTON|AMBULATORY'),
	dcp_project_filtered_geom as (
		select a.*, b.wkb_geometry as geom from dcp_project_filtered a
			left join dcp_knownprojects b 
			on (a.dcp_name = b.project_id)),
	fill_missing_geom as (
		select a.*, (case when geom is null then b.polygons else geom end) as geom1
		from dcp_project_filtered_geom a
		left join project_geoms b
			on (a.dcp_name = b.projectid)),
	get_ulurp as (
		select a.*, b.dcp_ulurpnumber from fill_missing_geom a
		left join dcp_projectaction b on (a.dcp_projectid = b.dcp_project)),
	get_ulurp_geom as (
		select a.*, (case when geom1 is null then b.wkb_geometry else geom1 end) as geom2
		from get_ulurp a
		left join dcp_zoningmapamendments b
		on (a.dcp_ulurpnumber = b.ulurpno)) 
	select distinct 
		'DCP Application' as source,
		dcp_name as project_id,
		dcp_projectname as project_name,
		dcp_borough as borough,
		statuscode as project_status,
		dcp_numberofnewdwellingunits as number_of_units,
		NULL as date_projected,
    	NULL as date_closed,
    	dcp_projectcompleted as date_complete,
    	NULL as date_filed,
    	NULL as date_statusd,
    	NULL as date_statusp,
    	NULL as date_permittd,
    	NULL as date_statusr,
    	NULL as date_statusx,
    	NULL as date_lastupdt, 
		NULL as inactive, 
		NULL as project_type, 
		geom2 as geom,
		dcp_projectcompleted,
		dcp_certifiedreferred, 
		dcp_residentialsqft, 
		dcp_applicanttype, 
		dcp_projectbrief, 
		dcp_projectdescription
	into dcp_application
	from get_ulurp_geom;