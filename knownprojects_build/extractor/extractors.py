import sys

import geopandas as gpd
import pandas as pd

from . import current_dir, output_dir
from .utils import ETL, hash_each_row


def dcp_knownprojects():
    return None


@ETL
def esd_projects() -> pd.DataFrame:
    filename = "2021.2.10 State Developments for Housing Pipeline.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def edc_projects() -> pd.DataFrame:
    filename = "2021.02.01 EDC inputs for DCP housing projections .xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def dcp_n_study() -> pd.DataFrame:
    filename = "2021.02.09 N'hood Study Rezoning Commitments.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


@ETL
def dcp_n_study_future() -> pd.DataFrame:
    filename = "2021.02.09 Future Rezonings.xlsx"
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


def hpd_pc():
    # Need data still
    return None


def dcp_planneradded():
    return None


def dcp_housing():
    # Taken from edm-data Need to check expected schema
    return None


def edc_sca_inputs():
    # "edc_2018_sca_inputs_share.zip"
    # Is this the same data as last year?
    return None


@ETL
def edc_dcp_inputs() -> gpd.geodataframe.GeoDataFrame:
    filename1 = "edc_shapefile_20191008.zip"
    filename2 = "WilletsPt_PhaseOne_Housing.zip"
    df1 = gpd.read_file(f"zip://{current_dir}/data/raw/{filename1}")
    df2 = gpd.read_file(
        f"zip://{current_dir}/data/raw/{filename2}!WilletsPt_PhaseOne_Housing/WilletsPt_PhaseOne_Housing.shp"
    )
    df2 = df2.to_crs(epsg=4326)
    df = pd.concat([df1, df2])
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
