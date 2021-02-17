import geopandas as gpd
import pandas as pd
from . import current_dir, output_dir
from .utils import hash_each_row, ETL
import sys

def dcp_knownprojects():
    return None


@ETL
def esd_projects() -> pd.DataFrame:
    filename = "2021.2.10 State Developments for Housing Pipeline.xlsx"
    df = pd.read_excel(f"{current_dir}/data/raw/{filename}", dtype=str)
    return df


def edc_projects():
    # "2021.02.01 EDC inputs for DCP housing projections.xlsx"
    return None


def dcp_n_study():
    # "2021.02.09 N'hood Study Rezoning Commitments.xlsx"
    return None


def dcp_n_study_future():
    # "2021.02.09 Future Rezonings.xlsx"
    return None

@ETL
def dcp_n_study_projected() -> gpd.geodataframe.GeoDataFrame:
    filename = "nstudy_rezoning_commitments_shapefile_20191008.zip"
    df = gpd.read_file(f"zip://{current_dir}/data/raw/{filename}")
    return df


def hpd_rfp():
    # "2021.02.08 HPD RFPs.xlsx"
    # Previous version did not have geometry, we take geometries from BBLs here.
    # What is "hpd_rfps_shapefile_20191008.zip," and how should we incorporate it?
    return None


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


def edc_dcp_inputs():
    # "edc_shapefile_20191008.zip", with "WilletsPt_PhaseOne_Housing.zip" appended
    return None


def dcp_rezoning():
    # "nyc_rezonings.zip" and/or "future_nstudy_shapefile_20191008.zip" It looks like the first contains the second
    return None


if __name__ == "__main__":
    name = sys.argv[1]
    assert name in list(locals().keys()), f"{name} is invalid"
    locals()[name]()