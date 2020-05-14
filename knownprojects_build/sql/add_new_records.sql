-- Add previously filtered DOB based on kpdb_corrections
INSERT INTO kpdb."2020"
(SELECT	NULL as project_id,
        record_id,
		record_name,
        NULL as borough,
        status,
        type,
        date,
        date_type,
        units_gross,
        NULL as units_net,
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
                        FROM kpdb_corrections
                        WHERE field = 'add')
    AND record_id NOT IN (SELECT DISTINCT record_id
                        FROM kpdb."2020"));

		