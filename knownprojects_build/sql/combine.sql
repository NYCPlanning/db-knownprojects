DROP TABLE if exists combined;
create table combined as (
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, null as portion_built_by_2025, 
        null as portion_built_by_2035, null as portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from dcp_application
    union
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from dcp_planneradded_proj
    union
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from dcp_n_study_proj
    union
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from edc_projects_proj
    union
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from esd_projects_proj
    union
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from hpd_rfp_proj
    union
    select 
        source, project_id::text, project_name, 
        project_status, project_type,
        number_of_units::integer, date, date_type, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, adjusted_units,
        inactive, geom
    from hpd_pc_proj
);