from helper.engines import recipe_engine, edm_engine, build_engine
from helper.exporter import exporter
from sqlalchemy import create_engine
import pandas as pd
import numpy as np
import os
from cartoframes.auth import set_default_credentials
from cartoframes import read_carto
from shapely import wkb
import geopandas as gpd
from datetime import date

year = 'test'

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

# Get cluster data from carto
print("Loading cluster data from carto...")
cluster_gdf = read_carto(f'clusters_{year}')
cluster_gdf.rename(columns={'the_geom':'geom'}, inplace=True)
reviewed_gdf = read_carto(f'clusters_unresolved_{year}')
reviewed_gdf.rename(columns={'the_geom':'geom'}, inplace=True)

# Export to postgres
today = date.today()
date = today.strftime("%Y-%m-%d")

cluster_table = f"clusters.\"{year}\""
reviewed_table = f"reviewed_clusters.\"{year}\""

DDL = {"source":"text",
    "record_id":"text",
    "record_name":"text",
    "status":"text",
    "inactive":"text",
    "type":"text",
    "date":"text",
    "date_type":"text",
    "timeline":"text",
    "dcp_projectcompleted":"text",
    "units_gross":"text",
    "units_net":"text",
    "cluster_id":"text",
    "sub_cluster_id":"text",
    "review_initials":"text",
    "review_notes":"text",
    "geom":"geometry(geometry,4326)"}


# Export to build engine
print("Exporting to build engine...")
exporter(cluster_gdf, cluster_table, DDL, 
            con=build_engine, 
            sql='', 
            sep='$', 
            geo_column='geom', SRID=4326)

DDL.pop("units_net")

exporter(reviewed_gdf, reviewed_table, DDL, 
            con=build_engine,
            sql='', 
            sep='$', 
            geo_column='geom', SRID=4326)
