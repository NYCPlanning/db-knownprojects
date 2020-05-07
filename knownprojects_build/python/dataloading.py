from cook import Importer
import os

RECIPE_ENGINE = os.environ.get("RECIPE_ENGINE", "")
BUILD_ENGINE = os.environ.get("BUILD_ENGINE", "")
EDM_DATA = os.environ.get("EDM_DATA", "")


def ETL():
    importer = Importer(RECIPE_ENGINE, BUILD_ENGINE)
    importer.import_table(schema_name="dcp_knownprojects")
    importer.import_table(schema_name="esd_projects")
    importer.import_table(schema_name="edc_projects")
    importer.import_table(schema_name="dcp_n_study")
    importer.import_table(schema_name="dcp_n_study_future")
    importer.import_table(schema_name="dcp_n_study_projected")
    importer.import_table(schema_name="hpd_rfp")
    importer.import_table(schema_name="hpd_pc")
    importer.import_table(schema_name="dcp_planneradded")
    # shapefiles
    importer.import_table(schema_name="edc_sca_inputs")
    importer.import_table(schema_name="edc_dcp_inputs")
    importer.import_table(schema_name="dcp_rezoning")
    # spatial data
    importer.import_table(schema_name="dcp_mappluto")
    importer.import_table(schema_name="dcp_zoningmapamendments")


def data():
    importer = Importer(EDM_DATA, BUILD_ENGINE)
    importer.import_table(schema_name="dcp_housing")


if __name__ == "__main__":
    ETL()
    data()
