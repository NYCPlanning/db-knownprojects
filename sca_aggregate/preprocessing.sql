-- Create standardization of tables for sca aggregate scripts 

ALTER TABLE doe_eszones RENAME COLUMN wkb_geometry TO geom;

ALTER TABLE doe_school_subdistricts RENAME COLUMN wkb_geometry TO geom;

ALTER TABLE dcp_school_districts RENAME COLUMN wkb_geometry TO geom;