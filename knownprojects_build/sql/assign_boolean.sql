with
stringy_proj as (
	select record_id, 
        rtrim(ltrim(replace(edc_projects::text, ',', ''), '('), ')') as stringy
		from edc_projects
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_application::text, ',', ''), '('), ')') as stringy
		from dcp_application
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_housing::text, ',', ''), '('), ')') as stringy
		from dcp_housing
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_housing::text, ',', ''), '('), ')') as stringy
		from dcp_housing
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_n_study::text, ',', ''), '('), ')') as stringy
		from dcp_n_study
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_n_study_future::text, ',', ''), '('), ')') as stringy
		from dcp_n_study_future
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_n_study_projected::text, ',', ''), '('), ')') as stringy
		from dcp_n_study_projected
	union
	select record_id, 
        rtrim(ltrim(replace(esd_projects::text, ',', ''), '('), ')') as stringy
		from esd_projects
	union
	select record_id, 
        rtrim(ltrim(replace(hpd_pc::text, ',', ''), '('), ')') as stringy
		from hpd_pc
	union
	select record_id, 
        rtrim(ltrim(replace(hpd_rfp::text, ',', ''), '('), ')') as stringy
		from hpd_rfp
	union
	select record_id, 
        rtrim(ltrim(replace(dcp_planneradded::text, ',', ''), '('), ')') as stringy
		from dcp_planneradded),
nycha_records as (
	select record_id from stringy_proj
	where stringy ~* 'NYCHA|BTP|HOUSING AUTHORITY|NEXT GEN|NEXT-GEN|NEXTGEN|NEXTGEN'
	union
	select record_id from kpdb_gross."2020"
	where record_name ~* 'NYCHA|BTP|HOUSING AUTHORITY|NEXT GEN|NEXT-GEN|NEXTGEN|NEXTGEN'),
gq_flag as (
	select record_id from stringy_proj
	where stringy ~* 'CORRECTIONAL|NURSING| MENTAL|DORMITOR|MILITARY|GROUP HOME|BARRACK'
	union
	select record_id from kpdb_gross."2020"
	where record_name ~* 'CORRECTIONAL|NURSING| MENTAL|DORMITOR|MILITARY|GROUP HOME|BARRACK'),
senior_flag as (
	select record_id from stringy_proj
	where stringy ~* 'SENIOR|ELDERLY| AIRS |A.I.R.S|CONTINUING CARE|NURSING| SARA |S.A.R.A'
	union
	select record_id from kpdb_gross."2020"
	where record_name ~* 'SENIOR|ELDERLY| AIRS |A.I.R.S|CONTINUING CARE|NURSING| SARA |S.A.R.A'),
assisted_flag as (
	select record_id from stringy_proj
	where stringy ~* 'ASSISTED LIVING'
	union
	select record_id from kpdb_gross."2020"
	where record_name ~* 'ASSISTED LIVING')
update kpdb_gross."2020"
set nycha = (case when record_id in (select record_id from nycha_records) then 1 else 0 end),
	gq = (case when record_id in (select record_id from gq_flag) then 1 else 0 end),
	senior_housing = (case when record_id in (select record_id from senior_flag) then 1 else 0 end),
	assisted_living = (case when record_id in (select record_id from assisted_flag) then 1 else 0 end);