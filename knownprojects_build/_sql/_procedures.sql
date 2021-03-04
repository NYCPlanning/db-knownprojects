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

/*
Procedure to reassign a multiple record_ids to a different or new project.
Works by calling reassign_single_record on the first in an array of record_ids
to reassign, then assigns subsequent record_ids to the same project as that
first record.
*/
CREATE OR REPLACE PROCEDURE reassign_multiple_records(
	record_id_array text array,
	record_id_match text
) AS $$
DECLARE
	_record_id text;
	_first_record_id text;
BEGIN
	SELECT record_id_array[1] INTO _first_record_id;
	
	-- Move first record_id, either to existing project or new project
	CALL reassign_single_record(_first_record_id, record_id_match);
	
	-- Remove first record_id from array, then loop through the remaining record_ids	
	record_id_array = array_remove(record_id_array, _first_record_id);
	
	<<reassign_remaining>>
	FOREACH _record_id IN ARRAY record_id_array LOOP
	    -- Add record_id to cluster containing record_id_match
		CALL reassign_single_record(_record_id, _first_record_id);
	END LOOP reassign_remaining;
	
END
$$ LANGUAGE plpgsql;

/*
Calls the above reassign functions, depending on whether the input for records
to reassign is a single record_id or a comma-separated list.
*/
CREATE OR REPLACE PROCEDURE apply_reassign(
	record_id text,
	record_id_match text
) AS $$
DECLARE
	_is_multiple boolean;
	_record_id_array text array;
BEGIN
	SELECT record_id LIKE '%,%' INTO _is_multiple;
	
	IF NOT _is_multiple THEN
		CALL reassign_single_record(record_id, record_id_match);

	ELSE
		SELECT string_to_array(REPLACE(record_id, ' ', ''), ',') INTO _record_id_array;
		CALL reassign_multiple_records(_record_id_array, record_id_match);
	END IF;
END
$$ LANGUAGE plpgsql;