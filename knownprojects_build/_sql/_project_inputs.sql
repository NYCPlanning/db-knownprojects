/*
DESCRIPTION:
    Create initial table of project inputs (groups of record_ids that refer to the
    same project) by calling stored procedures.

INPUTS: 
	_combined(

	)

    POST-REVIEW: project_input_corrections(

    )
OUTPUTS: 
    _project_inputs(
        
    )
*/

-- Identify spatial matched between projects
CALL non_dob_match();

/* 
Apply corrections to the project_inputs table.
If this is the first run and there are no corrections,
create an empty project_input_corrections so no corrections
get applied.
*/

CREATE TABLE IF NOT EXISTS project_input_corrections(
    record_id text,
    action text,
    record_id_match text
);

CALL correct_project_inputs();