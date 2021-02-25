CREATE TEMP TABLE dcp_housing as (
    SELECT 
        job_number,
        address,
        bbl,
        job_status,
        job_type,
        classa_net,
        date_permittd,
        date_filed,
        date_lastupdt,
        date_complete,
        job_inactive
    FROM dcp_housing.:"VERSION"  
    WHERE job_type <> 'Demolition'
    AND job_status <> '9. Withdrawn'
    AND classa_net::integer <> 0
    AND classa_prop::integer > 0
    AND NOT (job_type = 'Alteration'
        AND classa_net::integer <= 0)
);

\COPY dcp_housing TO PSTDOUT DELIMITER ',' CSV HEADER;