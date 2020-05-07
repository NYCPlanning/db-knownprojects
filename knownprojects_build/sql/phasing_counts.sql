UPDATE kpdb."2020"
SET within_5_years = ROUND(COALESCE(prop_within_5_years::decimal,0) * units_net::decimal),
    from_5_to_10_years = ROUND(COALESCE(prop_5_to_10_years::decimal,0) * units_net::decimal),
    after_10_years = ROUND(COALESCE(prop_after_10_years::decimal,0) * units_net::decimal);
