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
                        project_status,
                        project_type,
                        number_of_units,
                        geom)
    				SELECT 
                        source,
                        record_id,
                        record_name,
                        project_status,
                        project_type,
                        number_of_units,
                        geom
				FROM %I; ', tbl);
END;
$$;