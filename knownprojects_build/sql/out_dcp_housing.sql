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
);

\COPY dcp_housing TO PSTDOUT DELIMITER ',' CSV HEADER;