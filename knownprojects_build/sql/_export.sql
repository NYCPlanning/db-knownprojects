/*
DESCRIPTION:
    Map KPDB data into final schema for export.

INPUTS: 
    _kpdb

OUTPUTS: 
    kpdb
*/
DROP TABLE IF EXISTS kpdb;
SELECT
    source,
    record_id,
    record_name,
    borough,
    status,
    type,
    date,
    date_type,
    units_gross,
    units_net,
    prop_within_5_years,
    prop_5_to_10_years,
    prop_after_10_years,
    within_5_years,
    from_5_to_10_years,
    after_10_years,
    phasing_rationale,
    phasing_known,
    classb,
    nycha,
    senior_housing,
    inactive,
    geom
INTO kpdb
FROM _kpdb;
