/*******************************************************************************************************************************************
Sources: _kpdb - Finalized version of KPDB build 
		 doe_eszones

OUTPUT: longform_es_zone_output
*******************************************************************************************************************************************/




SELECT
	*
into
	aggregated_es_zone_project_level
from
(
	SELECT
		source,
		record_id,
		record_name,
		type,
		inactive,
		status,
		borough,
		units_gross,
		units_net,
		prop_within_5_years,
		prop_5_to_10_years,
		prop_after_10_years,
		within_5_years,
		from_5_to_10_years,
		after_10_years,
		phasing_rationale,
		phasing_known,
		date,
		date_type,
		nycha,
		classb,
		senior_housing,
		array_to_string(
			array_agg(
				nullif(
					concat_ws
					(
						': ',
						nullif
							(
								es_zone_remarks,
								''
							),
						concat(round(100*proportion_in_es_zone,0),'%')
					),
				'')),
		' | ') 	as es_zone,
		geom as geometry
		--geometry_webmercator
	from
		aggregated_es_zone_longform
	group by
		geometry,
		--geometry_webmercator,
		source,
		record_id,
		record_name,
		type,
		inactive,
		status,
		borough,
		units_gross,
		units_net,
		prop_within_5_years,
		prop_5_to_10_years,
		prop_after_10_years,
		within_5_years,
		from_5_to_10_years,
		after_10_years,
		phasing_rationale,
		phasing_known,
		date,
		date_type,
		nycha,
		classb,
		senior_housing
) x;

/*
	Output final ES-zone-based KPDB. This is not at the project-level, but rather the project & ES-level. It also omits Complete DOB jobs,
  	as these jobs should not be included in the forward-looking KPDB pipeline.

  	EP update 2021 - we now include completed DOB jobs in KPDB and SCA allocations
*/

SELECT
	*
into
	longform_es_zone_output
	from
(
SELECT *  FROM aggregated_es_zone_longform 
--where not (source = 'DOB' and status in('DOB 5. Completed Construction'))
	order by 
		source asc,
		record_id asc,
		record_name asc,
		status asc
) x;