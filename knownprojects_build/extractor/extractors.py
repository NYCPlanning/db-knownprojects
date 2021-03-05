import sys

import geopandas as gpd
import pandas as pd
import shapely

from . import current_dir, output_dir
from .utils import ETL, hash_each_row

@ETL
def dcp_knownprojects() -> pd.DataFrame:
    filename = "kpdb_2020_09_24_vF.csv"
    df = pd.read_csv(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df

@ETL
def esd_projects() -> pd.DataFrame:
    filename = "2021.2.10 State Developments for Housing Pipeline.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def edc_projects() -> pd.DataFrame:
    filename = "2021.02.25 EDC inputs for DCP housing projections.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def dcp_n_study() -> pd.DataFrame:
    filename = "2021.02.09 N'hood Study Rezoning Commitments.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def dcp_n_study_future() -> pd.DataFrame:
    filename = "2021.02.25 Future Rezonings.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def dcp_n_study_projected() -> gpd.geodataframe.GeoDataFrame:
    filename = "nstudy_rezoning_commitments_shapefile_20191008.zip"
    df = gpd.read_file(f"zip://{current_dir}/data/raw/{filename}")
    return df


@ETL
def hpd_rfp() -> pd.DataFrame:
    filename = "2021.02.08 HPD RFPs.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df

@ETL
def hpd_pc() -> pd.DataFrame:
    filename = "2021_2_18 DCP_SCA Pipeline.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def dcp_planneradded():
    filename = "dcp_planneradded_2020_04_03.csv"
    df = pd.read_csv(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def edc_dcp_inputs() -> gpd.geodataframe.GeoDataFrame:
    filename = "edc_shapefile_20210225"
    df = gpd.read_file(f"zip://{current_dir}/data/raw/{filename}.zip!{filename}/{filename}.shp")
    return df


@ETL
def dcp_rezoning() -> gpd.geodataframe.GeoDataFrame:
    filename = "nyc_rezonings.zip"
    df = gpd.read_file(f"zip://{current_dir}/data/raw/{filename}")
    return df


if __name__ == "__main__":
    name = sys.argv[1]
    assert name in list(locals().keys()), f"{name} is invalid"
    locals()[name]()
