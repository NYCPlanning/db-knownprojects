-- Create zap_project_many_bbls table as used in previous iterations of the SCA aggregate scripts

DROP TABLE IF EXISTS zap_project_many_bbls;

-- Create the zap_projects table
CREATE TABLE zap_project_many_bbls (
     record_id text
);

-- Insert only distinct values from dcp_projects into zap_projects
INSERT INTO zap_project_many_bbls (record_id)
SELECT DISTINCT dcp_name FROM dcp_projects;