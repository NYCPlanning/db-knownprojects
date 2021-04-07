DROP TABLE IF EXISTS review_project;
WITH 
_review_project AS (
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
        array_to_string(b.project_record_ids, ',') as project_record_ids,
        cardinality(b.project_record_ids) as records_in_project,
        (cardinality(b.project_record_ids) > 1)::integer as multirecord_project,
        b.dummy_id,
        (a.geom IS NULL)::integer as no_geom,
        a.geom,
        NOW() as v
    FROM combined a
    LEFT JOIN (
            SELECT 
                project_record_ids,
                unnest(project_record_ids) as record_id, 
                ROW_NUMBER() OVER(ORDER BY project_record_ids) as dummy_id
            FROM _project_record_ids
        ) b 
    ON a.record_id = b.record_id
    WHERE source NOT IN ('DOB', 'Neighborhood Study Rezoning Commitments', 'Future Neighborhood Studies')
),
project_extent AS (
    SELECT
        dummy_id,
        ST_Area(ST_SetSRID(ST_Extent(geom), 4326)::geography) as bbox_area
    FROM _review_project
    GROUP BY dummy_id
)
SELECT
    a.*,
    b.bbox_area
INTO review_project
FROM _review_project a
JOIN project_extent b
ON a.dummy_id = b.dummy_id;