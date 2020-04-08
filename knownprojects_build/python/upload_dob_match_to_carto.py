import os
from helper.engines import recipe_engine, edm_engine, build_engine
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb
import geopandas as gpd

year = 'test'

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

sql = 'select * from dob_review'
df = gpd.GeoDataFrame.from_postgis(sql, build_engine, geom_col='geom')
to_carto(df, f'dob_review_{year}', if_exists='replace')