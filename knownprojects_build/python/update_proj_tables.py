from helper.engines import recipe_engine, edm_engine, build_engine
from helper.exporter import exporter
import pandas as pd
import numpy as np
import os

year = 'test'

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
    # Add columns
    sql_add_fields = f'''
    ALTER TABLE {table}
    ADD COLUMN IF NOT EXISTS cluster_id text,
    ADD COLUMN IF NOT EXISTS sub_cluster_id text,
    ADD COLUMN IF NOT EXISTS adjusted_units text;
    '''

    # Update project-level table with cluster-review results
    sql_update = f'''
    UPDATE {table} a
    SET cluster_id = b.cluster_id,
        sub_cluster_id = b.sub_cluster_id,
        adjusted_units = b.adjusted_units
    FROM clusters."{year}" b
    WHERE a.source = b.source
    AND a.project_id::text = b.project_id::text
    AND a.project_name = b.project_name;
    '''

    print(f"\n\nAdding cluster fields to {table}...")
    build_engine.execute(sql_add_fields)
    print(f"Updating {table} with cluster-review results...")
    build_engine.execute(sql_update)

    # Create cluster IDs for one-record clusters
    print(f"Creating IDs for one record clusters in {table}...")
    df = pd.read_sql(f'SELECT * FROM {table}', build_engine)
    num_nulls = df[df['cluster_id'].isna()].shape[0]
    df.loc[df['cluster_id'].isna(),'cluster_id'] = pd.Series(range(largest_cluster, largest_cluster + num_nulls)).astype(str)
    df.loc[df['sub_cluster_id'].isna(),'sub_cluster_id'] = '1'
    df.loc[df['adjusted_units'].isna(),'adjusted_units'] = df['number_of_units']
    largest_cluster = largest_cluster + num_nulls

    # Export to temporary table
    print(f"Creating temporary look-up table for {table}...")
    columns = ['source','project_id','project_name','cluster_id','sub_cluster_id','adjusted_units']
    df[columns].to_sql('tmp', con=build_engine, if_exists='replace', index=False)

    print(f"Updating source {table} with one-record IDs.")
    sql_update=f'''UPDATE {table} a
                SET cluster_id = b.cluster_id,
                    sub_cluster_id = b.sub_cluster_id,
                    adjusted_units = b.adjusted_units
                FROM tmp b
                WHERE a.source = b.source
                AND a.project_id::text = b.project_id::text
                AND a.project_name = b.project_name;
                '''
    build_engine.execute(sql_update)
    build_engine.execute('DROP TABLE tmp;')

