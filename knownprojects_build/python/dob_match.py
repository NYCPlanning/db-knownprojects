from helper.engines import recipe_engine, edm_engine, build_engine
from sqlalchemy import create_engine
import pandas as pd
import numpy as np
import networkx as nx
import os
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb
import geopandas as gpd

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

if not os.path.exists('review'):
        os.makedirs('review')

year = 'test'

# Sources to include in clusters
tables = ['dcp_application',
        'dcp_planneradded_proj',
        'dcp_n_study_proj',
        'edc_projects_proj',
        'esd_projects_proj',
        'hpd_rfp_proj',
        'hpd_pc_proj']

# Hierarchy to use for perfect count-match deduplication
hierarchy = {'DOB':0,
            'HPD Projected Closings':1,
            'HPD RFPs':2,
            'EDC Projected Projects':3,
            'DCP Application':4,
            'Empire State Development Projected Projects':5,
            'Neighborhood Study Rezoning Commitments':6,
            'Neighborhood Study Projected Development Sites':7,
            'DCP Planner-Added Projects':8}

# Expected timeline for sorting date fields
timeline = {'DOB':5,
            'HPD Projected Closings':3,
            'HPD RFPs':2,
            'EDC Projected Projects':4,
            'DCP Application':1,
            'Empire State Development Projected Projects':0,
            'Neighborhood Study Rezoning Commitments':0,
            'Neighborhood Study Projected Development Sites':0,
            'DCP Planner-Added Projects':0}

r = []
for i in tables:
    table_a = i
    table_b = 'dcp_housing_proj'
    sql = f'''
    WITH part_a as (
    SELECT
        a.*, a.source as a_source, 
        a.project_id::text as a_project_id, 
        a.project_name as a_project_name, 
        b.source as b_source, 
        b.project_id::text as b_project_id, 
        b.project_name as b_project_name
    FROM {table_a} a 
    JOIN {table_b} b
    ON st_intersects(a.geom, b.geom)
    AND split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 1 < extract(year from b.date::timestamp)),
    part_b as (
    SELECT b.*, 
        a.source as a_source, 
        a.project_id::text as a_project_id, 
        a.project_name as a_project_name, 
        b.source as b_source, 
        b.project_id::text as b_project_id, 
        b.project_name as b_project_name,
        a.cluster_id,
        a.sub_cluster_id
    FROM {table_a} a 
    JOIN {table_b} b
    ON st_intersects(a.geom, b.geom)
    AND split_part(split_part(a.date, '/', 1), '-', 1)::numeric - 1 < extract(year from b.date::timestamp))
    SELECT 
        a_source, 
        a_project_id, 
        a_project_name, 
        b_source, 
        b_project_id, 
        b_project_name,
        source, 
        project_id::text, 
        project_name, 
        date::text, 
        date_type, 
        dcp_projectcompleted::text,
        project_status, 
        adjusted_units::integer as number_of_units, 
        inactive,
        project_type, 
        ST_Multi(geom) as geom, 
        cluster_id, 
        sub_cluster_id
    FROM part_a
    UNION
    SELECT 
        a_source, 
        a_project_id, 
        a_project_name, 
        b_source, 
        b_project_id, 
        b_project_name,
        source, 
        project_id::text, 
        project_name, 
        date::text, 
        date_type, 
        dcp_projectcompleted::text, 
        project_status, 
        number_of_units::integer,
        inactive,project_type, 
        ST_Multi(geom) as geom, 
        cluster_id, 
        sub_cluster_id
    FROM part_b
    '''
    df = pd.read_sql(sql, build_engine)
    r.append(df)

dff = pd.concat(r)

# Map heirarchy & timeline to combined data, output pairwise comparisson
print("Assigning source hierarcy and expected timeline to each record...")
dff['source_id'] = dff['source'].map(hierarchy)
dff['timeline'] = dff['source'].map(timeline).astype(int)
# dff.to_csv('review/dob_pairwise.csv')

# Create unique ID
print("Creating a unique ID...")
dff['uid'] = dff['source'] + dff['project_id'] + dff['project_name']
dff['id'] = dff.apply(lambda x: [x['a_source']+x['a_project_id']+x['a_project_name'],
                                x['b_source']+x['b_project_id']+x['b_project_name']], axis=1)

# Create graph object and identify connected components
print("Creating intersection graph...")
G=nx.Graph()
G.add_edges_from(dff['id'].to_list())
components = [c for c in nx.connected_components(G)]
print('\nNumber of clusters found: ', len(components))

print("Assigning dob cluster ID...")
r = []
a = 0
for i in components:
    df = dff.loc[dff.uid.isin(list(i)), 
        ['source', 'project_id', 'project_name', 'project_status', 
        'number_of_units','date', 'date_type', 'dcp_projectcompleted',
        'inactive', 'project_type', 'geom', 'source_id', 'timeline',
        'cluster_id', 'sub_cluster_id']]
    df['dob_cluster_id'] = a
    a += 1
    r.append(df)
dfff = pd.concat(r).drop_duplicates().reset_index()
dfff.to_sql('dob_match_test', build_engine, if_exists='replace', index=False)

# Drop duplicates
dfff = pd.concat(r).drop_duplicates().reset_index()

# Deduplicate exact count matches
print("Resolving clusters where all records have the same number of units...")
def dedup_exacts(group):
    group.loc[:,'adjusted_units']=group['number_of_units']
    if group.shape[0] > 1:
        if group.source_id.unique().shape[0] > 1:
            top_priority = min(group.source_id.unique())
            group.loc[group['source_id'] != top_priority, 'adjusted_units'] = 0.0
    return group

dfff.sort_values(by=['dob_cluster_id','source_id'])
dfff.number_of_units.fillna(value=99999, inplace=True) # Temporarily fill null so that it can be used as groupby
deduped = dfff.groupby(['dob_cluster_id','number_of_units'], as_index=False)\
                .apply(dedup_exacts)
deduped.number_of_units.replace(99999, np.nan, inplace=True)
deduped.adjusted_units.replace(99999, np.nan, inplace=True) # Reset null
deduped['dob_sub_cluster_id'] = 1

# Process to remove resolved clusters, if desired
print("Removing resolved clusters from the review table...")
grouped = deduped.groupby('dob_cluster_id')
remove_clusters = []
for name, group in grouped:
    non_zero = group[group['adjusted_units'] != 0]
    if non_zero.shape[0] == 1:
        print("Cluster resolved by exact-count match: ",name)
        remove_clusters.append(name)

deduped.timeline.replace(0, np.nan, inplace=True)
deduped['timeline'] = deduped['timeline'].astype(str)          
deduped['timeline'] = deduped['timeline'].str.replace('.0', '').str.replace('nan', '')
deduped = deduped.sort_values(by=['dob_cluster_id','timeline'])

# Export full cluster table
print("Exporting full cluster table...")
deduped_export = deduped[['source', 'project_id', 'project_name', 'project_status', 
                        'inactive', 'project_type','date', 'date_type','timeline', 
                        'dcp_projectcompleted', 'number_of_units', 'adjusted_units', 
                        'cluster_id','sub_cluster_id', 'dob_cluster_id', 
                        'dob_sub_cluster_id', 'geom']]

multi_group = deduped_export\
            .loc[deduped_export.source=='DOB', :]\
            .groupby('project_id')
multi = multi_group.filter(lambda x: len(x) > 1)
multi_id = multi.project_id.to_list()
deduped_export['review_flag'] = deduped_export['project_id']\
                                    .apply(lambda x: 1 if x in multi_id else 0)
print("\n\nSize of full cluster table: ", deduped_export.shape)
deduped_export.to_csv(f'review/dob_clusters_{year}.csv', index=False)
gdf=gpd.GeoDataFrame(deduped_export)
gdf['geometry'] = gdf.geom.apply(lambda x: wkb.loads(x, hex=True))
to_carto(gdf, f'dob_clusters_{year}', if_exists='replace')

# Export only unresolved clusters for review
print("Exporting unresolved cluster table for review...")
unresolved = deduped_export[~deduped_export['dob_cluster_id']\
                    .isin(remove_clusters)]\
                        .drop(columns=['adjusted_units'])
print("\n\nSize of unresolved cluster review table: ", unresolved.shape)
unresolved.to_csv(f'review/dob_clusters_unresolved_{year}.csv', index=False)
gdf=gpd.GeoDataFrame(unresolved)
gdf['geometry'] = gdf.geom.apply(lambda x: wkb.loads(x, hex=True))
to_carto(gdf, f'dob_clusters_unresolved_{year}', if_exists='replace')