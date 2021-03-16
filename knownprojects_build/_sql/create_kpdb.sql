DROP TABLE IF EXISTS _kpdb;
SELECT
    a.*,
    b.units_net
INTO _kpdb
FROM _combined a
LEFT JOIN deduped_units b
ON a.record_id = b.record_id;