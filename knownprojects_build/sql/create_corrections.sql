-- first round of corrections -> project to project
DROP TABLE IF EXISTS corrections_project;
CREATE TABLE corrections_project(
    record_id text,
    action text,
    record_id_match text
);

\COPY corrections_project FROM 'data/corrections/corrections_project.csv' DELIMITER ',' CSV HEADER;

-- second round of corrections -> dob to project
DROP TABLE IF EXISTS corrections_dob_match;
CREATE TABLE corrections_dob_match(
    record_id text,
    action text,
    record_id_dob text
);

\COPY corrections_dob_match FROM 'data/corrections/corrections_dob.csv' DELIMITER ',' CSV HEADER;

-- main corrections table -> all other fields
DROP TABLE IF EXISTS corrections_main;
CREATE TABLE corrections_main(
    record_id text,
    field text,
    old_value text,
    new_value text,
    editor text,
    date text,
    record_name text,
    notes text
);

\COPY corrections_main FROM 'data/corrections/corrections_main.csv' DELIMITER ',' CSV HEADER;
