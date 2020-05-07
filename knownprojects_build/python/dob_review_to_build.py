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

year = os.environ.get('VERSION', 'test')

set_default_credentials(
    username=os.environ.get("CARTO_USERNAME"), api_key=os.environ.get("CARTO_APIKEY")
)

# Get dob-review data from carto
print("Loading dob-review data from carto...")
dob_review_gdf = read_carto(f"dob_review_{year}")
dob_review_gdf.rename(columns={"the_geom": "geom"}, inplace=True)
print(list(dob_review_gdf))

# Export to postgres
today = date.today()
date = today.strftime("%Y-%m-%d")
reviewed_table = f'reviewed_dob_match."{year}"'

DDL = {
    "source": "text",
    "record_id": "text",
    "record_name": "text",
    "status": "text",
    "inactive": "text",
    "type": "text",
    "date": "text",
    "date_type": "text",
    "date_filed": "text",
    "date_complete": "text",
    "dcp_projectcompleted": "text",
    "units_gross": "text",
    "project_id": "text",
    "dob_multimatch": "text",
    "needs_review": "text",
    "dob_review_initials": "text",
    "review_notes": "text",
    "incorrect_match": "text",
    "geom": "geometry(geometry,4326)",
}


# Export to build engine
print("Exporting to build engine...")
exporter(
    dob_review_gdf,
    reviewed_table,
    DDL,
    con=build_engine,
    sql="",
    sep="$",
    geo_column="geom",
    SRID=4326,
)
