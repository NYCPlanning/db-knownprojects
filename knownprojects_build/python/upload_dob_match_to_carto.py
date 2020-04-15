import os
from helper.engines import recipe_engine, edm_engine, build_engine
from cartoframes.auth import set_default_credentials
from cartoframes import to_carto
from shapely import wkb
import geopandas as gpd

year = 'zapurl'

set_default_credentials(
    username=os.environ.get('CARTO_USERNAME'),
    api_key=os.environ.get('CARTO_APIKEY')
)

sql = '''
    SELECT 
        a.source, a.project_id, 
        a.project_name, a.project_status, a.inactive,
        a.project_type,  b.zap_search_url, a.number_of_units::integer, 
        a.date, a.date_type, a.dcp_projectcompleted,
        a.review_notes, a.development_id, 
        a.dob_multimatch, a.needs_review,
        a.geom
    FROM dob_review a
    LEFT JOIN dcp_application b
    ON a.source = b.source
        AND a.project_id = b.project_id
        AND a.project_name = b.project_name
    ORDER BY development_id;
    '''
    
df = gpd.GeoDataFrame.from_postgis(sql, build_engine, geom_col='geom')
df['dob_review_initials'] = ''
to_carto(df, f'dob_review_{year}', if_exists='replace')