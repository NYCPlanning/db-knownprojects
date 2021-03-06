DROP TABLE if exists combined;
create table combined as (
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type, 
        null as date_filed, null as date_complete,
        dcp_projectcompleted, null as portion_built_by_2025, 
        null as portion_built_by_2035, null as portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from dcp_application_proj
    union
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type,
        null as date_filed, null as date_complete, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from dcp_planneradded_proj
    union
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type,
        null as date_filed, null as date_complete, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from dcp_n_study_proj
    union
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type,
        null as date_filed, null as date_complete, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from edc_projects_proj
    union
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type,
        null as date_filed, null as date_complete, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from esd_projects_proj
    union
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type,
        null as date_filed, null as date_complete, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from hpd_rfp_proj
    union
    select 
        source, record_id::text, record_name, 
        status, type,
        units_gross::integer, date, date_type,
        null as date_filed, null as date_complete, 
        dcp_projectcompleted, portion_built_by_2025, 
        portion_built_by_2035, portion_built_by_2055, 
        cluster_id, sub_cluster_id, review_initials, review_notes,
        cluster_id||'-'||sub_cluster_id as project_id,
        units_net,
        inactive, geom
    from hpd_pc_proj
);