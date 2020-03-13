-- Create a procedure that can load each source data
-- into one table at source record/bbl level
CREATE OR REPLACE PROCEDURE load_to_geoms(tbl text)
LANGUAGE plpgsql
AS $$
BEGIN
    execute format('INSERT INTO 
    				bbl_geoms(
                        source,
                        project_id,
                        project_name,
                        bbl,
                        geom)
    				SELECT 
                        source,
                        project_id,
                        project_name,
                        bbl,
                        geom
				FROM %I; ', tbl);
END;
$$;