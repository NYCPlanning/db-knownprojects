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

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

# Get cluster data from carto
print("Loading cluster data from carto...")
cluster_gdf = read_carto('clusters', limit=100)
reviewed_gdf = read_carto('clusters_unresolved', limit=100)

# Export to postgres
today = date.today()
date = today.strftime("%Y-%m-%d")

cluster_table = "clusters.\"2020\""
reviewed_table = "reviewed_clusters.\"2020\""

DDL = {"source":"text",
    "project_id":"text",
    "project_name":"text",
    "project_status":"text",
    "inactive":"text",
    "project_type":"text",
    "date":"text",
    "date_type":"text",
    "timeline":"text",
    "dcp_projectcompleted":"text",
    "number_of_units":"text",
    "cluster_id":"text",
    "sub_cluster_id":"text",
    "geom":"geometry(MultiPolygon,4326)"}


# Export to build engine
print("Exporting to build engine...")
exporter(cluster_gdf, cluster_table, DDL.update{"adjusted_units":"text"}, 
            con=build_engine, 
            sql='', 
            sep='$', 
            geo_column='geom', SRID=4326)

exporter(reviewed_gdf, reviewed_table, DDL, 
            con=build_engine,
            sql='', 
            sep='$', 
            geo_column='geom', SRID=4326)
