-- excute the load_to_projects procedure for each dataset
CALL load_to_projects('dcp_application_proj');
CALL load_to_projects('dcp_housing_proj');
CALL load_to_projects('dcp_n_study_future_proj');
CALL load_to_projects('dcp_n_study_projected_proj');
CALL load_to_projects('dcp_n_study_proj');
CALL load_to_projects('edc_projects_proj');
CALL load_to_projects('esd_projects_proj');
CALL load_to_projects('hpd_pc_proj');
CALL load_to_projects('hpd_rfp_proj');