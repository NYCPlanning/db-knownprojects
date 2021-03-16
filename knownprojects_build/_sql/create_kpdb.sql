DROP TABLE IF EXISTS _kpdb;
SELECT
    a.*,
    b.units_net,
    ROUND(COALESCE(a.prop_within_5_years::decimal,0) * b.units_net::decimal) as within_5_years,
    ROUND(COALESCE(a.prop_5_to_10_years::decimal,0) * b.units_net::decimal) as from_5_to_10_years,
    ROUND(COALESCE(a.prop_after_10_years::decimal,0) * b.units_net::decimal) as after_10_years
INTO _kpdb
FROM _combined a
LEFT JOIN deduped_units b
ON a.record_id = b.record_id;