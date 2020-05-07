UPDATE kpdb."2020"
SET within_5_years = prop_within_5_years::decimal * units_net::decimal,
    from_5_to_10_years = prop_5_to_10_years::decimal * units_net::decimal,
    after_10_years = prop_after_10_years::decimal * units_net::decimal,
    phasing_assume_or_known = 'Assumed';
