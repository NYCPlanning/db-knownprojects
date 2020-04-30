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
    group.loc[:,'units_net']=group['units_gross']
    if group.shape[0] > 1:
        if group.source_id.unique().shape[0] > 1:
            top_priority = min(group.source_id.unique())
            group.loc[group['source_id'] != top_priority, 'units_net'] = 0.0
    return group

def subtract_units(row, group):
    higher_priority = group[group['source_id'] < row['source_id']]
    higher_priority_units = higher_priority['units_net'].sum()
    row['units_net'] = row['units_net'] - higher_priority_units
    if row['units_net'] < 0:
        row['units_net'] = 0
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
            'Neighborhood Study Projected Development Sites':8,
            'DCP Planner-Added Projects':9}

    df['source_id'] = df['source'].map(hierarchy)
    df['verified_cluster'] = df['cluster_id'].astype(str) + '.' + df['sub_cluster_id'].astype(str)

    # Deduplicate exact count matches
    print("Deduplicating exact count matches...")
    df.sort_values(by=['verified_cluster','source_id'])
    df.units_gross.fillna(value=99999, inplace=True) # Temporarily fill null so that it can be used as groupby
    deduped = df.groupby(['verified_cluster','units_gross'], as_index=False).apply(dedup_exacts)
    deduped.units_gross.replace(99999, np.nan, inplace=True)
    deduped.units_net.replace(99999, np.nan, inplace=True) # Reset null

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
        resolved[['source', 'units_gross', 'units_net', 'cluster_id', 'sub_cluster_id']].head(10))
    resolved.to_csv('review/resolved_clusters.csv', index=False)

    '''
    gdf=gpd.GeoDataFrame(resolved)
    gdf['geometry'] = gdf.geom.apply(lambda x: wkb.loads(x, hex=True))
    to_carto(gdf, 'resolved_clusters', if_exists='replace')
    '''

    return resolved