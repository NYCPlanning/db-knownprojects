import geopandas as gpd
import pandas as pd

"""
tracked in https://github.com/NYCPlanning/db-knownprojects/issues/206
"""

def dcp_knownprojects():
    return None

def esd_projects(): 
    # "2021.2.10 State Developments for Housing Pipeline.xlsx"
    return None
def edc_projects(): 
    # "2021.02.01 EDC inputs for DCP housing projections.xlsx"
    return None

def dcp_n_study(): 
    # "2021.02.09 N'hood Study Rezoning Commitments.xlsx"
    return None

def dcp_n_study_future(): 
    # "2021.02.09 Future Rezonings.xlsx"
    return None

def dcp_n_study_projected(): 
    # "nstudy_rezoning_commitments_shapefile_20191008.zip"
    return None

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
