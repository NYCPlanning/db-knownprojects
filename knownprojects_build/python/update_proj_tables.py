from helper.engines import recipe_engine, edm_engine, build_engine
from helper.exporter import exporter
import pandas as pd
import numpy as np
import os

year = '2020'

# Sources included in clusters
tables = ['dcp_application',
        'dcp_planneradded_proj',
        'dcp_n_study_proj',
        'edc_projects_proj',
        'esd_projects_proj',
        'hpd_rfp_proj',
        'hpd_pc_proj']

# Get maximum cluster ID
sql_get_max = f'''
    SELECT max(cluster_id::integer)
    FROM clusters."{year}";
    '''
largest_cluster = int(pd.read_sql(sql_get_max, build_engine).values[0][0])

# Loop through source tables to update with cluster info
for table in tables:
    sql_add_fields = f'''
    ALTER TABLE {table}
    ADD COLUMN IF NOT EXISTS cluster_id text,
    ADD COLUMN IF NOT EXISTS sub_cluster_id text,
    ADD COLUMN IF NOT EXISTS adjusted_units text;
    '''

    sql_update = f'''
    UPDATE {table} a
    SET cluster_id = b.cluster_id,
        sub_cluster_id = b.sub_cluster_id,
        adjusted_units = b.adjusted_units,
    FROM clusters.{year} b
    WHERE a.source = b.source
    AND a.project_id::text = b.project_id::text
    AND a.project_name = b.project_name;
    '''

    build_engine.execute(sql_add_fields)
    build_engine.execute(sql_update)

    df = pd.read_sql(f'SELECT * FROM {table}', build_engine)
    num_nulls = df[df['cluster_id'].isna()].shape[0]
    df.loc[df['cluster_id'].isna(),'cluster_id'] = pd.Series(range(largest_cluster, largest_cluster + num_nulls))
    largest_cluster = largest_cluster + num_nulls



