CREATE SCHEMA IF NOT EXISTS kpdb_gross;
DROP TABLE IF EXISTS kpdb_gross.:"VERSION";
CREATE TABLE kpdb_gross.:"VERSION" as (
    SELECT 
    source, record_id::text, record_name, 
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
    source, record_id::text, record_name, 
    status, type, units_gross::integer, 
    date, date_type, date_filed, date_complete,
    dcp_projectcompleted, null as portion_built_by_2025, 
    null as portion_built_by_2035, null as portion_built_by_2055, 
    null as project_id,
    null as units_net,
    inactive, geom
from dcp_housing_proj);

VACUUM ANALYZE kpdb_gross.:"VERSION";

UPDATE kpdb_gross.:"VERSION" a
SET project_id = b.project_id
from reviewed_dob_match.:"VERSION" b
where a.source = 'DOB'
and b.source = 'DOB'
and a.record_id = b.record_id
and a.record_name = b.record_name
and b.incorrect_match = '0';

VACUUM ANALYZE kpdb_gross.:"VERSION";

-- additional columns
ALTER TABLE kpdb_gross.:"VERSION"
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

VACUUM ANALYZE kpdb_gross.:"VERSION";

with
max_proj as (
	select max(split_part(project_id, '-', 1)::integer) as max_proj_number
    from kpdb_gross.:"VERSION"),
tmp as (
	select
		a.source, 
		a.record_id, 
		a.record_name,
		coalesce(a.units_net::integer, a.units_gross::integer) as units_net,
		(ROW_NUMBER() OVER (ORDER BY record_id) + b.max_proj_number)::text||'-1' as project_id
	from kpdb_gross.:"VERSION" a, max_proj b
	where a.project_id is null)
update kpdb_gross.:"VERSION" a
	set project_id = b.project_id,
		units_net = b.units_net
	FROM tmp b
	WHERE a.source='DOB'
	AND b.source='DOB'
	AND a.record_id = b.record_id
	AND a.record_name=b.record_name;
    
VACUUM ANALYZE kpdb_gross.:"VERSION";
