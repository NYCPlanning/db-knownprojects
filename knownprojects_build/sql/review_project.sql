DROP TABLE IF EXISTS review_project;
SELECT
    a.source,
    a.record_id,
    a.record_name,
    a.status,
    a.type,
    a.units_gross,
    a.date,
    a.date_type,
    a.prop_within_5_years,
    a.prop_5_to_10_years,
    a.prop_after_10_years,
    a.phasing_known,
    a.nycha,
    a.classb,
    a.senior_housing,
    b.project_record_ids,
    (cardinality(b.project_record_ids) > 1)::integer as multirecord_project,
    b.project_id,
    a.geom
INTO review_project
FROM _combined a
LEFT JOIN (
        SELECT 
            project_record_ids,
            unnest(project_record_ids) as record_id, 
            ROW_NUMBER() OVER(ORDER BY project_record_ids) as project_id
        FROM _project_record_ids
    ) b 
ON a.record_id = b.record_id
WHERE source NOT IN ('DOB', 'Neighborhood Study Rezoning Commitments', 'Future Neighborhood Studies');