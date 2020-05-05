from helper.engines import recipe_engine, edm_engine, build_engine
from helper.exporter import exporter
import pandas as pd
import numpy as np
import os

year = 'test'


print(f"Making kpdb with {year} reviewed DOB data...")
sql_make_kpdb = f'''
    CREATE SCHEMA IF NOT EXIST kpdb;

    CREATE TABLE kpdb."{year}" as (
        SELECT 
        source, record_id::text, record_name, 
        status, type, units_gross::integer, 
        date, date_type, date_filed, date_complete,
        dcp_projectcompleted, null as portion_built_by_2025, 
        null as portion_built_by_2035, null as portion_built_by_2055, 
        project_id,
        units_net,
        inactive, geom
    from combined
    union
    select 
        source, record_id::text, record_name, 
        status, type, units_gross::integer, 
        date, date_type, date_filed, date_complete,
        dcp_projectcompleted, null as portion_built_by_2025, 
        null as portion_built_by_2035, null as portion_built_by_2055, 
        null as project_id,
        null as units_net,
        inactive, geom
    from dcb_housing_proj)
'''
print(f"\n\nCombining DOB and non-DOB data into kpdb.{year}...")
build_engine.execute(sql_make_kpdb)

sql_update_dob = f'''
UPDATE kpdb."{year}" a
    SET project_id = b.project_id,
    FROM reviewed_dob_match."{year}" b
    WHERE a.source = 'DOB'
    AND b.source = 'DOB'
    AND a.record_id = b.record_id
    AND a.record_name = b.record_name
    AND b.incorrect_match = 0;
'''
print(f"Updating kpdb.{year} with DOB-review results...")
build_engine.execute(sql_update_dob)

# Get maximum project ID
sql_get_max = f'''
    SELECT max(SPLIT_PART(project_id, '-', 1)::integer)
    FROM kpdb."{year}";
    '''
largest_project_id = int(pd.read_sql(sql_get_max, build_engine).values[0][0])

# Add columns
sql_add_fields = f'''
ALTER TABLE kpdb."{year}"
ADD COLUMN IF NOT EXISTS within_5_years text,
ADD COLUMN IF NOT EXISTS 5_to_10_years text,
ADD COLUMN IF NOT EXISTS after_10_years text,
ADD COLUMN IF NOT EXISTS phasing_rationale text,
ADD COLUMN IF NOT EXISTS phasing_assume_or_known text,
ADD COLUMN IF NOT EXISTS nycha text,
ADD COLUMN IF NOT EXISTS gq text,
ADD COLUMN IF NOT EXISTS senior_housing text,
ADD COLUMN IF NOT EXISTS assisted_living text;
'''
print(f"\n\nAdding fields to kpdb.{year}...")
build_engine.execute(sql_add_fields)

# Create cluster IDs for stand-alone DOB records
print(f"Creating IDs for stand-alone DOB records in kpdb.{year}...")
df = pd.read_sql(f'SELECT * FROM kpdb."{year}"', build_engine)
num_nulls = df[df['project_id'].isna()].shape[0]
df.loc[df['project_id'].isna(),'project_id'] = pd.Series(range(largest_project_id, largest_project_id + num_nulls)).astype(str)
df.loc[~df['project_id'].str.contains('-')],'project_id'] = df['project_id'] + '-1'
df.loc[df['units_net'].isna(),'units_net'] = df['units_gross']

# Reformat numbers
df['project_id'] = df.cluster_id.replace('\.0', '', regex=True)
df['units_net'] = df.units_net.replace('\.0', '', regex=True)

# Export to temporary table
print(f"Creating temporary look-up table for kpdb.{year}...")
columns = ['source','record_id','record_name','project_id','units_net']
df[columns].to_sql('tmp', con=build_engine, if_exists='replace', index=False)

print(f"Updating kpdb.{year} with one-record IDs.")
sql_update=f'''UPDATE kpdb."{year}" a
            SET project_id = b.project_id,
                units_net = b.units_net
            FROM tmp b
            WHERE a.source = 'DOB'
            AND b.source = 'DOB'
            AND a.record_id::text = b.record_id::text
            AND a.record_name = b.record_name;
            '''
build_engine.execute(sql_update)
build_engine.execute('DROP TABLE tmp;')


