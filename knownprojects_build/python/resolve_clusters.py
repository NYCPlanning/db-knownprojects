import pandas as pd
import numpy as np
import os
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb
import geopandas as gpd

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

def dedup_exacts(group):
    group.loc[:,'adjusted_units']=group['number_of_units']
    if group.shape[0] > 1:
        if group.source_id.unique().shape[0] > 1:
            top_priority = min(group.source_id.unique())
            group.loc[group['source_id'] != top_priority, 'adjusted_units'] = 0.0
    return group

def subtract_units(row, group):
    higher_priority = group[group['source_id'] < row['source_id']]
    higher_priority_units = higher_priority['adjusted_units'].sum()
    row['adjusted_units'] = row['adjusted_units'] - higher_priority_units
    if row['adjusted_units'] < 0:
        row['adjusted_units'] = 0
    return row

def resolve_cluster(group):
    if group.shape[0] > 1:
        group = group.reset_index()
        for index, row in group.iterrows():
            group.iloc[index] = subtract_units(row, group)
    return group

def resolve_all_clusters(df):
    # Hierarchy to use for perfect count-match deduplication
    hierarchy = {'DOB': 1,
            'HPD Projected Closings':2,
            'HPD RFPs':3,
            'EDC Projected Projects':4,
            'DCP Application':5,
            'Empire State Development Projected Projects':6,
            'Neighborhood Study Rezoning Commitments':7,
            'Neighborhood Study Projected Development Sites':8}

    df['source_id'] = df['source'].map(hierarchy)
    df['verified_cluster'] = df['cluster_id'].astype(str) + '.' + df['sub_cluster_id'].astype(str)

    # Deduplicate exact count matches
    print("Deduplicating exact count matches...")
    df.sort_values(by=['verified_cluster','source_id'])
    df.number_of_units.fillna(value=99999, inplace=True) # Temporarily fill null so that it can be used as groupby
    deduped = df.groupby(['verified_cluster','number_of_units'], as_index=False).apply(dedup_exacts)
    deduped.number_of_units.replace(99999, np.nan, inplace=True)
    deduped.adjusted_units.replace(99999, np.nan, inplace=True) # Reset null

    # Subtract units within cluster based on hierarchy
    print("Subtracting units within verified clusters based on source hierarchy...")
    resolved = deduped.groupby(['verified_cluster'], as_index=False).apply(resolve_cluster)
    try:
        resolved = resolved.drop(columns=['level_0'])
    except:
        pass
    try:
        resolved = resolved.drop(columns=['index'])
    except:
        pass
    try:
        resolved = resolved.drop(columns=['verified_cluster'])
    except:
        pass
    print("Output of resolved clusters: \n", 
        resolved[['source', 'number_of_units', 'adjusted_units', 'cluster_id', 'sub_cluster_id']].head(10))
    resolved.to_csv('review/resolved_clusters.csv', index=False)

    '''
    gdf=gpd.GeoDataFrame(resolved)
    gdf['geometry'] = gdf.geom.apply(lambda x: wkb.loads(x, hex=True))
    to_carto(gdf, 'resolved_clusters', if_exists='replace')
    '''

    return resolved