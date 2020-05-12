with pick_boro as (
	select 
		a.record_id, 
		b.boroname, 
		st_area(st_intersection(st_makevalid(a.geom), b.wkb_geometry)) as area
	from kpdb."2020" a, dcp_boroboundaries_wi b
	where  st_intersects(st_makevalid(a.geom), b.wkb_geometry)),
pick_boro_ordered as (
	select 
		record_id, 
		boroname, area, 
		ROW_NUMBER() OVER(PARTITION BY record_id ORDER BY area DESC) AS row_number
	from pick_boro
	order by record_id, row_number)
UPDATE kpdb."2020" a
SET borough = b.boroname
FROM pick_boro_ordered b
WHERE a.record_id = b.record_id and b.row_number = 1;