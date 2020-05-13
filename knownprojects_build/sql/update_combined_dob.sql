CREATE SCHEMA IF NOT EXISTS kpdb_gross;
DROP TABLE IF EXISTS kpdb_gross."2020";
CREATE TABLE kpdb_gross."2020" as (
    SELECT 
    source, record_id::text, record_name, null as borough,
    status, type, units_gross::integer, 
    date, date_type, date_filed, date_complete,
    dcp_projectcompleted, null as portion_built_by_2025, 
    null as portion_built_by_2035, null as portion_built_by_2055, 
    project_id,
    units_net,
    inactive, geom
from combined
union
select 
    source, record_id::text, record_name, null as borough,
    status, type, units_gross::integer, 
    date, date_type, date_filed, date_complete,
    dcp_projectcompleted, null as portion_built_by_2025, 
    null as portion_built_by_2035, null as portion_built_by_2055, 
    null as project_id,
    null as units_net,
    inactive, geom
from dcp_housing_proj);

VACUUM ANALYZE kpdb_gross."2020";

UPDATE kpdb_gross."2020" a
SET project_id = b.project_id
from reviewed_dob_match."2020" b
where a.source = 'DOB'
and b.source = 'DOB'
and a.record_id = b.record_id
and a.record_name = b.record_name
and b.incorrect_match = '0';

VACUUM ANALYZE kpdb_gross."2020";

-- additional columns
ALTER TABLE kpdb_gross."2020"
    ADD COLUMN IF NOT EXISTS prop_within_5_years text,
    ADD COLUMN IF NOT EXISTS prop_5_to_10_years text,
    ADD COLUMN IF NOT EXISTS prop_after_10_years text,
    ADD COLUMN IF NOT EXISTS within_5_years text,
    ADD COLUMN IF NOT EXISTS from_5_to_10_years text,
    ADD COLUMN IF NOT EXISTS after_10_years text,
    ADD COLUMN IF NOT EXISTS phasing_rationale text,
    ADD COLUMN IF NOT EXISTS phasing_known text,
    ADD COLUMN IF NOT EXISTS nycha text,
    ADD COLUMN IF NOT EXISTS gq text,
    ADD COLUMN IF NOT EXISTS senior_housing text,
    ADD COLUMN IF NOT EXISTS assisted_living text;

VACUUM ANALYZE kpdb_gross."2020";

with
max_proj as (
	select max(split_part(project_id, '-', 1)::integer) as max_proj_number
    from kpdb_gross."2020"),
tmp as (
	select
		a.source, 
		a.record_id, 
		a.record_name,
		coalesce(a.units_net::integer, a.units_gross::integer) as units_net,
		(ROW_NUMBER() OVER (ORDER BY record_id) + b.max_proj_number)::text||'-1' as project_id
	from kpdb_gross."2020" a, max_proj b
	where a.project_id is null)
update kpdb_gross."2020" a
	set project_id = b.project_id,
		units_net = b.units_net
	FROM tmp b
	WHERE a.source='DOB'
	AND b.source='DOB'
	AND a.record_id = b.record_id
	AND a.record_name=b.record_name;
    
VACUUM ANALYZE kpdb_gross."2020";

UPDATE kpdb_gross."2020"
SET units_net=coalesce(units_net::integer, units_gross::integer);

UPDATE kpdb_gross."2020" a
SET project_id=b.new_value
FROM kpdb_corrections b
where b.field = 'project_id'
and a.record_id = b.record_id 
and a.project_id=b.old_value;