-- QC queries

-- stats about geometries at source record/bbl level and project level
DROP TABLE IF EXISTS qc_geoms_stats;
CREATE TABLE qc_geoms_stats AS (
    SELECT a.*, b.prj_count, b.prj_nongeom_count, b.proj_nongeom_pct
    FROM
    (SELECT source, COUNT(*) AS bbl_count,
    SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) AS bbl_nongeom_count,
    CAST(100.0 * SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(16,2)) AS bbl_nongeom_pct
    FROM bbl_geoms
    GROUP BY source) AS a
    LEFT JOIN (
    SELECT source, COUNT(*) AS prj_count,
    SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) AS prj_nongeom_count,
    CAST(100.0 * SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(16,2)) AS proj_nongeom_pct
    FROM project_geoms
    GROUP BY source) AS b
    ON a.source = b. source
    ORDER BY proj_nongeom_pct DESC
);

-- source records that does not have matching bbl geometries in Mappluto
DROP TABLE IF EXISTS qc_bbl_needgeoms;
CREATE TABLE qc_bbl_needgeoms AS (
    SELECT * FROM bbl_geoms
    WHERE geom IS NULL
);

-- projects that does not have matching bbl geometries in Mappluto
DROP TABLE IF EXISTS qc_project_needgeoms;
CREATE TABLE qc_project_needgeoms AS (
    SELECT * FROM project_geoms
    WHERE geom IS NULL
);