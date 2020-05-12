UPDATE kpdb."2020" a
SET borough = b.boroname
FROM dcp_boroboundaries_wi b
WHERE st_intersects(st_makevalid(a.geom), b.wkb_geometry);