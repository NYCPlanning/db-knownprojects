from helper.engines import recipe_engine, edm_engine, build_engine
from helper.exporter import exporter
import pandas as pd
import numpy as np
import os
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb
import geopandas as gpd

year='2020'

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

def subtract_units(row, group):
    higher_priority = group[group['source_id'] < row['source_id']]
    higher_priority_units = higher_priority['units_net'].sum()
    row['units_net'] = row['units_net'] - higher_priority_units
    if row['units_net'] < 0:
        row['units_net'] = 0
    return row

def resolve_project(group):
    if group.shape[0] > 1:
        group = group.reset_index()
        for index, row in group.iterrows():
            group.iloc[index] = subtract_units(row, group)
    return group

def resolve_all_projects(df):
    # Hierarchy for unit subtraction
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

    # Subtract units within cluster based on hierarchy
    print("Subtracting units within projcts based on source hierarchy...")
    resolved = df.groupby(['project_id'], as_index=False).apply(resolve_project)
    try:
        resolved = resolved.drop(columns=['level_0'])
    except:
        pass
    try:
        resolved = resolved.drop(columns=['index'])
    except:
        pass
    print("Output of unit subtraction: \n", 
        resolved[['source', 'units_gross', 'units_net', 'project_id']].head(10))
    resolved.to_csv(f'review/kpdb_{year}.csv', index=False)

    '''
    gdf=gpd.GeoDataFrame(resolved)
    gdf['geometry'] = gdf.geom.apply(lambda x: wkb.loads(x, hex=True))
    to_carto(gdf, 'resolved_clusters', if_exists='replace')
    '''
    return resolved

if __name__ == "__main__":
    resolved_table = f"kpdb.\"{year}\""

    df = pd.read_sql(f'SELECT * FROM kpdb_gross."{year}"', build_engine)
    df['units_gross'] = df['units_gross'].astype(float)
    df['units_net'] = df['units_net'].astype(float)
    resolved = resolve_all_projects(df)

    DDL = {"project_id":"text",
    "source":"text",
    "record_id":"text",
    "record_name":"text",
    "status":"text",
    "type":"text",
    "date":"text",
    "date_type":"text",
    "units_gross":"text",
    "units_net":"text",
    "prop_within_5_years":"text",
    "prop_5_to_10_years":"text",
    "prop_after_10_years":"text",
    "within_5_years":"text",
    "from_5_to_10_years":"text",
    "after_10_years":"text",
    "phasing_rationale":"text",
    "phasing_assume_or_known":"text",
    "nycha":"text",
    "gq":"text",
    "senior_housing":"text",
    "assisted_living":"text",
    "inactive":"text",
    "geom":"geometry(geometry,4326)"}

    print("Exporting resolved kpdb to build engine...")
    exporter(resolved, resolved_table, DDL, 
                con=build_engine, 
                sql='', 
                sep='$', 
                geo_column='geom', SRID=4326)
