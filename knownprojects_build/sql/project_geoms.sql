-- Create a schema for a table having all source data's
-- geometries at source level
DROP TABLE IF EXISTS project_geoms CASCADE;
CREATE TABLE project_geoms (
    source text,
    record_id text,
    record_name text,
    status text,
    type text,
    units_gross text,
    geom geometry(geometry,4326)
);