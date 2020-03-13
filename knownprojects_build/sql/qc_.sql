-- QC queries

-- stats about geometries at source record/bbl level
DROP TABLE IF EXISTS qc_bblgeoms_stats;
CREATE TABLE qc_bblgeoms_stats AS (
    SELECT source, COUNT(*) AS total_count, 
    SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) AS nongeom_count,
    CAST(100.0 * SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(16,2)) AS nongeom_pct
    FROM bbl_geoms
    GROUP BY source
    ORDER BY 100.0 * SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) / COUNT(*) DESC
);

-- records that does not have matching bbl geometries in Mappluto
DROP TABLE IF EXISTS qc_bbl_needgeoms;
CREATE TABLE qc_bbl_needgeoms AS (
    SELECT * FROM bbl_geoms
    WHERE geom IS NULL
);