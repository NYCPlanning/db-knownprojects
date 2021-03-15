CREATE TEMP TABLE deduped_units (
    record_id text,
    source_text text,
    units_gross text,
    units_net text,
    project_id text
);

\COPY deduped_units FROM PSTDIN DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS _kpdb;
SELECT
    a.*,
    b.units_net
INTO _kpdb
FROM _combined a
JOIN deduped_units b
ON a.record_id = b.record_id;