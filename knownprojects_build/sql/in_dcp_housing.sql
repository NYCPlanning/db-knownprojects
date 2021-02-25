DROP TABLE IF EXISTS dcp_housing;
CREATE TEMP TABLE tmp (
    job_number text,
    address text,
    bbl text,
    job_status text,
    job_type text,
    classa_net integer,
    date_permittd text,
    date_filed text,
    date_lastupdt text,
    date_complete text,
    job_inactive text
);

\COPY tmp FROM PSTDIN DELIMITER ',' CSV HEADER;

SELECT
    'DOB' as source,
    a.job_number as record_id,
    a.address as record_name,
    a.job_status as status,
    a.job_type as type,
    a.classa_net as units_net,
    (CASE
        WHEN a.date_permittd LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_permittd, 'YYYY-MM-DD'), 'YYYY/MM/DD')
        ELSE NULL
    END) as date,
    'Date Permitted' as date_type,
    (CASE
        WHEN a.date_filed LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_filed, 'YYYY-MM-DD'), 'YYYY/MM/DD')
        ELSE NULL
    END) as date_filed,
    (CASE
        WHEN a.date_lastupdt LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_lastupdt, 'YYYY-MM-DD'), 'YYYY/MM/DD')
        ELSE NULL
    END) as date_lastupdt,
    (CASE
        WHEN a.date_complete LIKE '%-%' THEN TO_CHAR(TO_DATE(a.date_complete, 'YYYY-MM-DD'), 'YYYY/MM/DD')
        ELSE NULL
    END) as date_complete,
    NULL::numeric as dcp_projectcompleted,
    NULL::numeric as portion_built_by_2025,
    NULL::numeric as portion_built_by_2035,
    NULL::numeric as portion_built_by_2055,
    (CASE WHEN job_inactive = 'Inactive' THEN 1 ELSE 0 END) as inactive,
    b.wkb_geometry
INTO dcp_housing
FROM tmp a
LEFT JOIN dcp_mappluto b
ON a.bbl = b.bbl::bigint::text;