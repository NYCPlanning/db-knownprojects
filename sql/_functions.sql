/*
FLAG FUNCTIONS
*/
CREATE OR REPLACE FUNCTION flag_classb(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'ASSISTED LIVING|CORRECTIONAL|NURSING| MENTAL|DORMITOR|MILITARY|GROUP HOME|BARRACK')::integer;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION flag_senior_housing(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'SENIOR|ELDERLY| AIRS |A.I.R.S|CONTINUING CARE| SARA |S.A.R.A')::integer;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION flag_nycha(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'NYCHA|BTP|HOUSING AUTHORITY|NEXT GEN|NEXT-GEN|NEXTGEN')::integer;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION get_boro(_geom geometry) 
RETURNS varchar AS $$
    SELECT b.borocode::varchar
    FROM dcp_boroboundaries_wi b
    WHERE ST_Within(_geom, b.wkb_geometry)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION ten_percent_within_boundary(_geom geometry) 
RETURNS boolean AS $$
	SELECT
		b.the_geom,
        CAST(ST_Area(ST_INTERSECTion(ST_makevalid(the_geom), ST_makevalid(b.the_geom))) / ST_Area(ST_makevalid(the_geom)) AS DECIMAL) >= .1 as 
	FROM nyc_school_districts b
	on ST_INTERSECTs(ST_makevalid(the_geom), ST_makevalid(b.the_geom)) and CAST(ST_Area(ST_INTERSECTion(ST_makevalid(the_geom), ST_makevalid(b.the_geom))) / ST_Area(ST_makevalid(the_geom)) AS DECIMAL) >= .1
$$ LANGUAGE sql;

