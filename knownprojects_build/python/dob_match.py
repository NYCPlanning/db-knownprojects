from helper.engines import recipe_engine, edm_engine, build_engine
from sqlalchemy import create_engine
import pandas as pd
import numpy as np
import os

# Sources to include in clusters
tables = ['dcp_application',
        'dcp_planneradded_proj',
        'dcp_n_study_proj',
        'edc_projects_proj',
        'esd_projects_proj',
        'hpd_rfp_proj',
        'hpd_pc_proj']

r = []
for i in tables:
    table_a = i
    table_b = 'dcp_housing_proj'
    sql = f'''
    SELECT
    a.cluster_id,
    a.sub_cluster_id,
    b.project_id
    FROM {table_a} a
    JOIN {table_b} b
    ON st_intersects(a.geom, b.geom)
    AND split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 1 < extract(year from b.date::timestamp)
    '''
    df = pd.read_sql(sql, build_engine)
    r.append(df)

dff = pd.concat(r)
dff=dff.drop_duplicates()
dff.to_sql('dob_match', build_engine)

reviewed_clusters='reviewed_clusters."2020-04-06"'
df_dob=pd.read_sql(f'''
    with multimatch as (
            select project_id, count(*) 
            from dob_match
            group by project_id
            having count(*) > 1),
        multimatch_w_cluster as (
            select *
            from dob_match
            where project_id in (
                select project_id
                FROM multimatch)
            order by cluster_id),
        formated as (
            select 
                b.source, 
                b.project_id,
                b.project_name,
                b.project_status,
                b.inactive,
                b.project_type,
                b.date,
                b.date_type,
                null as timeline,
                b.dcp_projectcompleted,
                b.number_of_units,
                a.cluster_id,
                a.sub_cluster_id,
                b.geom
        from multimatch_w_cluster a
        left join dcp_housing b
        on a.project_id = b.project_id)
        (select * from {reviewed_clusters})
        union
        (select * from formated);''', build_engine)