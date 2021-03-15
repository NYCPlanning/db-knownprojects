/* 
Apply corrections to the project_record_ids table.
If this is the first run and there are no corrections,
create an empty corrections_project so no corrections
get applied.
*/
DROP TABLE IF EXISTS corrections_project;
CREATE TABLE corrections_project(
    record_id text,
    action text,
    record_id_match text
);

\COPY corrections_project FROM 'data/corrections/corrections_project.csv' DELIMITER ',' CSV HEADER;