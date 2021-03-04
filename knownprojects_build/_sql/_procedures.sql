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
$$ LANGUAGE sql;

/*
Procedure to reassign a single record_id to a different or new project
*/
CREATE OR REPLACE PROCEDURE reassign_single_record(
	record_id text, 
	record_id_match text
) AS $$
DECLARE
    new_project boolean;
BEGIN
	SELECT record_id_match IS NULL INTO new_project;
	
	-- Remove record_id from its existing project
	UPDATE _project_inputs
	SET project_inputs = array_remove(project_inputs, record_id)
	WHERE record_id=any(project_inputs);
		
	IF NOT new_project THEN
		-- Add record_id to the project containing record_id_match
		UPDATE _project_inputs
		SET project_inputs = array_append(project_inputs, record_id) 
		WHERE record_id_match=any(project_inputs);
		
	ELSE
		-- Add record_id to a new project
		INSERT INTO _project_inputs(project_inputs)
		VALUES(array_append(array[]::text[], record_id)); 
	END IF;
END
$$ LANGUAGE plpgsql;
