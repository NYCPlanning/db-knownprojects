/*
FLAG FUNCTIONS
*/
CREATE OR REPLACE FUNCTION flag_assisted_living(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'ASSISTED LIVING')::integer;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION flag_senior_housing(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'SENIOR|ELDERLY| AIRS |A.I.R.S|CONTINUING CARE|NURSING| SARA |S.A.R.A')::integer;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION flag_gq(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'CORRECTIONAL|NURSING| MENTAL|DORMITOR|MILITARY|GROUP HOME|BARRACK')::integer;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION flag_nycha(stringy varchar) 
RETURNS integer AS $$
	SELECT (stringy ~* 
    'NYCHA|BTP|HOUSING AUTHORITY|NEXT GEN|NEXT-GEN|NEXTGEN|NEXTGEN')::integer;
$$ LANGUAGE sql;