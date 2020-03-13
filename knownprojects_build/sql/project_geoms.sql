-- Create a schema for a table having all source data's
-- geometries at source level
DROP TABLE IF EXISTS project_geoms CASCADE;
CREATE TABLE project_geoms (
    source text,
    project_id text,
    project_name text,
    project_status text,
    project_type text,
    number_of_units text,
    geom geometry(Geometry,4326)
);