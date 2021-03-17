DROP TABLE IF EXISTS review_project;
SELECT
    a.*,
    b.project_record_ids,
    (CASE
        WHEN cardinality(b.project_record_ids) > 1 THEN '1'
        ELSE '0'
    END) as multirecord_project,
    b.project_id
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