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
# g = dff.groupby('project_id')
# review = g.filter(lambda x: len(x) > 1)
# review.to_sql('dob_review', build_engine)
dff.to_sql('dob_match', build_engine)