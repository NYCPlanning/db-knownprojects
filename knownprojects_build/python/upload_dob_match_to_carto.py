import os
from helper.engines import recipe_engine, edm_engine, build_engine
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb
import geopandas as gpd

year = '2020'

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

sql = '''
    select 
        source, project_id::text, 
        project_name, project_status, inactive,
        project_type, number_of_units::integer, 
        date, date_type, date_permittd, date_complete,
        dcp_projectcompleted, review_notes, development_id, 
        dob_multimatch, needs_review,
        geom
    from dob_review
    order by development_id
    '''
df = gpd.GeoDataFrame.from_postgis(sql, build_engine, geom_col='geom')
df['dob_review_initials'] = ''
df['incorrect_match'] = 0
to_carto(df, f'dob_review_{year}', if_exists='replace')