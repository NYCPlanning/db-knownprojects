/*
DESCRIPTION:
    Create initial table of project inputs (groups of record_ids that refer to the
    same project) by calling stored procedures.

INPUTS: 
	_combined(

	)

    POST-REVIEW: correction_project(

    )
OUTPUTS: 
    _project_record_ids(
        
    )
*/

-- Identify spatial matched between projects
CALL non_dob_match();

/* 
Apply corrections to the project_record_ids table.
If this is the first run and there are no corrections,
create an empty correction_project so no corrections
get applied.
*/

CREATE TABLE IF NOT EXISTS correction_project(
    record_id text,
    action text,
    record_id_match text
);

CALL correct_project_record_ids();