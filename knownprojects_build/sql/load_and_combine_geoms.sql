DELETE FROM bbl_geoms;

ALTER TABLE dcp_application ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE dcp_housing ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE dcp_n_study_future ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE dcp_n_study_projected ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE dcp_n_study ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE edc_projects ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE esd_projects ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE hpd_pc ADD COLUMN IF NOT EXISTS bbl TEXT;
ALTER TABLE hpd_rfp ADD COLUMN IF NOT EXISTS bbl TEXT;


CALL load_to_geoms('dcp_application');
CALL load_to_geoms('dcp_housing');
CALL load_to_geoms('dcp_n_study_future');
CALL load_to_geoms('dcp_n_study_projected');
CALL load_to_geoms('dcp_n_study');
CALL load_to_geoms('edc_projects');
CALL load_to_geoms('esd_projects');
CALL load_to_geoms('hpd_pc');
CALL load_to_geoms('hpd_rfp');