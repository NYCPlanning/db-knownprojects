-- Create a procedure that can load each source data
-- into one table at project level
CREATE OR REPLACE PROCEDURE load_to_projects(tbl text)
LANGUAGE plpgsql
AS $$
BEGIN
    execute format('INSERT INTO 
    				project_geoms(
                        source,
                        record_id,
                        record_name,
                        status,
                        type,
                        units_gross,
                        geom)
    				SELECT 
                        source,
                        record_id,
                        record_name,
                        status,
                        type,
                        units_gross,
                        geom
				FROM %I; ', tbl);
END;
$$;