-- Create a schema for a table having all source data's
-- geometries at source level
DROP TABLE IF EXISTS bbl_geoms CASCADE;
CREATE TABLE bbl_geoms (
    source text,
    project_id text,
    project_name text,
    bbl text,
    geom geometry(Geometry,4326)
);