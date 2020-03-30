from helper.engines import recipe_engine, edm_engine, build_engine
from sqlalchemy import create_engine
import pandas as pd
import numpy as np
import networkx as nx
import os


if not os.path.exists('review'):
        os.makedirs('review')

# Sources to include in clusters
tables = ['dcp_application',
        'dcp_n_study_proj',
        'edc_projects_proj',
        'esd_projects_proj',
        'hpd_rfp_proj',
        'hpd_pc_proj']

# Hierarchy to use for perfect count-match deduplication
hierarchy = {'HPD Projected Closings':1,
            'HPD RFPs':2,
            'EDC Projected Projects':3,
            'DCP Application':4,
            'Empire State Development Projected Projects':5,
            'Neighborhood Study Rezoning Commitments':6,
            'Neighborhood Study Projected Development Sites':7}

# Compare all pairs
pair = []
for i in tables: 
    for j in tables:
        if tables.index(i) > tables.index(j):
            pair.append([i, j])
r = []
for i in pair:
    table_a = i[0]
    table_b = i[1]
    sql = f'''
    with part_a as (
    select a.*, a.source as a_source, a.project_id as a_project_id, a.project_name as a_project_name, b.source as b_source, b.project_id as b_project_id, b.project_name as b_project_name
    FROM {table_a} a 
    JOIN {table_b} b
    on st_intersects(a.geom, b.geom)),
    part_b as (
    select b.*, a.source as a_source, a.project_id as a_project_id, a.project_name as a_project_name, b.source as b_source, b.project_id as b_project_id, b.project_name as b_project_name
    FROM {table_a} a 
    JOIN {table_b} b
    on st_intersects(a.geom, b.geom))
    select a_source, a_project_id, a_project_name, b_source, b_project_id, b_project_name,
    source, project_id, project_name, date_projected::text, date_closed::text, date_complete::text,
    project_status, number_of_units::integer, 
    inactive, project_type, geom 
    FROM part_a
    UNION
    select a_source, a_project_id, a_project_name, b_source, b_project_id, b_project_name,
    source, project_id, project_name, date_projected::text, date_closed::text, date_complete::text,
    project_status, number_of_units::integer,
    inactive,project_type,geom
    FROM part_b
    '''
    df = pd.read_sql(sql, build_engine)
    r.append(df)

dff = pd.concat(r)


# Map heirarchy to combined data, output pairwise comparisson
dff['source_id'] = dff['source'].map(hierarchy)
dff.to_csv('review/pairwise.csv')

# Create unique ID
dff['uid'] = dff['source'] + dff['project_id'] + dff['project_name']
dff['id'] = dff.apply(lambda x: [x['a_source']+x['a_project_id']+x['a_project_name'],x['b_source']+x['b_project_id']+x['b_project_name']], axis=1)

# Create graph object and identify connected components
G=nx.Graph()
G.add_edges_from(dff['id'].to_list())
components = [c for c in nx.connected_components(G)]
print('\nNumber of connected components: ', len(components))

# Loop through components to assign cluster IDs
r = []
a = 0
for i in components:
    df = dff.loc[dff.uid.isin(list(i)), ['source',
       'project_id', 'project_name', 'project_status', 'number_of_units',
       'date_projected', 'date_closed', 'date_complete',
       'inactive', 'project_type', 'geom', 'source_id']]
    df['cluster_id'] = a 
    a += 1
    r.append(df)

# Output clustered records pre-automatic deduplication of exact count matches
dfff = pd.concat(r).drop_duplicates().reset_index()
dfff.to_csv('review/kpdb_review.csv', index=False)

# Deduplicate exact count matches
def dedup_exacts(group):
    group.loc[:,'adjusted_units']=group['number_of_units']
    if group.shape[0] > 1:
        if group.source_id.unique().shape[0] > 1:
            top_priority = min(group.source_id.unique())
            group.loc[group['source_id'] != top_priority, 'adjusted_units'] = 0.0
    return group

dfff.sort_values(by=['cluster_id','source_id'])
dfff.number_of_units.fillna(value=99999, inplace=True) # Temporarily fill null so that it can be used as groupby
deduped = dfff.groupby(['cluster_id','number_of_units'], as_index=False).apply(dedup_exacts)
deduped.number_of_units.replace(99999, np.nan, inplace=True)
deduped.adjusted_units.replace(99999, np.nan, inplace=True) # Reset null
deduped['sub_cluster_id'] = 1


# Process to remove resolved clusters, if desired
'''
grouped = deduped.groupby('cluster_id')
remove_clusters = []
for name, group in grouped:
    non_zero = group[group['adjusted_units'] != 0]
    if non_zero.shape[0] == 1:
        print(name)
        remove_clusters.append(name)

deduped = deduped[~deduped['cluster_id'].isin(remove_clusters)]
'''

# Export for review
deduped_export = deduped[['source', 'project_id', 'project_name', 'project_status', 'inactive', 'project_type',
                        'date_projected', 'date_closed', 'date_complete',
                        'number_of_units','adjusted_units','cluster_id','sub_cluster_id','geom']]
deduped_export.to_csv('review/kpdb_review_adjusted.csv', index=False)