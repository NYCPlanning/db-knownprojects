/* Procedure to match non-DOB records based on spatial overlap,
forming arrays of individual record_ids which will get called
project_inputs. Two of the neighborhood study sources are not
included, as units from these sources do not deduplicate
with other sources.

These project_inputs will get reviewed.
*/
CREATE OR REPLACE PROCEDURE non_dob_match(
) AS
$$
BEGIN
    DROP TABLE IF EXISTS _project_inputs;
    SELECT
        array_agg(record_id) as project_inputs
    INTO _project_inputs
    FROM(
        SELECT record_id, 
        ST_ClusterDBSCAN(geom, 0, 1) OVER() AS id
        FROM  _combined
        WHERE source NOT IN ('DOB', 'Neighborhood Study Rezoning Commitments', 'Future Neighborhood Studies')
    ) a
    WHERE id IS NOT NULL
    GROUP BY id;
END
$$ LANGUAGE sql;


