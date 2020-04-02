import pandas as pd
import numpy as np
import os
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

df = pd.read_csv('review/kpdb_review.csv')

# Hierarchy to use for perfect count-match deduplication
hierarchy = {'HPD Projected Closings':1,
            'HPD RFPs':2,
            'EDC Projected Projects':3,
            'DCP Application':4,
            'Empire State Development Projected Projects':5,
            'Neighborhood Study Rezoning Commitments':6,
            'Neighborhood Study Projected Development Sites':7}

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
    print('\n\n\n=== Initial cluster: ===\n', group)
    print('Number of records in cluster: ', group.shape[0])
    if group.shape[0] > 1:
        group = group.reset_index()
        for index, row in group.iterrows():
            print('\nProcessing group row: ', index)
            group.iloc[index] = subtract_units(row, group)
    print('\n=== Resolved cluster: ===\n', group)
    return group

#TODO: Function to subtract DOB units

# Deduplicate exact count matches
df.sort_values(by=['cluster_id','source_id'])
df.number_of_units.fillna(value=99999, inplace=True) # Temporarily fill null so that it can be used as groupby
deduped = df.groupby(['cluster_id','number_of_units'], as_index=False).apply(dedup_exacts)
deduped.number_of_units.replace(99999, np.nan, inplace=True)
deduped.adjusted_units.replace(99999, np.nan, inplace=True) # Reset null

# Subtract units within cluster based on hierarchy
resolved = deduped.groupby(['cluster_id'], as_index=False).apply(resolve_cluster)
resolved = resolved.drop(columns=['level_0','index'])
resolved.to_csv('review/resolved_clusters.csv', index=False)
gdf=gpd.GeoDataFrame(resolved)
gdf['geometry'] = gdf.geom.apply(lambda x: wkb.loads(x, hex=True))
to_carto(gdf, 'resolved_clusters', if_exists='replace')