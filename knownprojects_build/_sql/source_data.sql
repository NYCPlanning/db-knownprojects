WITH 
_dcp_n_study_future as (
    SELECT
        'Future Neighborhood Studies' as source, 
        a.uid as record_id,
        array_agg(a.uid) as record_id_input,
        neighborhood||' '||'Future Rezoning Development' as record_name,
        'Projected' as status,
        'Future Rezoning' as type,
        incremental_units_with_certainty_factor::numeric as units_gross,
        effective_year as date,
        'Effective Year' as date_type,
        null::numeric as portion_built_by_2025,
        null::numeric as portion_built_by_2035,
        null::numeric as portion_built_by_2055,
        ST_Union(b.geometry) as geom
    FROM dcp_n_study_future a
    LEFT JOIN  dcp_rezoning b
    ON a.neighborhood = b.study
    GROUP BY a.uid, neighborhood, effective_year, incremental_units_with_certainty_factor
),
_dcp_n_study_projected as (
    SELECT 
        'Neighborhood Study Projected Development Sites' as source,
        uid as record_id,
        array(select uid from dcp_n_study_projected where uid=uid) as record_id_input,
        REPLACE(project_id, ' Projected Development Sites', '') as record_name,
        'Projected Development' as status,
        NULL AS type,
        NULL::numeric as units_gross,
    --  TO_CHAR(TO_DATE(effective_date, 'MM/DD/YYYY'), 'YYYY/MM/DD') as date,
        NULL as date,
        'Effective Date' as date_type,
        portion_bu::numeric as portion_built_by_2025,
        portion__1::numeric as portion_built_by_2035,
        portion__2::numeric as portion_built_by_2055,
        geometry as geom
    FROM dcp_n_study_projected
),
_dcp_n_study as (
    SELECT 
        'Neighborhood Study Rezoning Commitments' as source,
        md5(array_to_string(array_agg(a.uid), '')) as record_id,
        array_agg(a.uid) as record_id_input,
        neighborhood_study||': '||commitment_site as record_name,
        'Rezoning Commitment' as status,
        NULL as type,
        (SELECT units_gross FROM kpdb."2020_06_25" 
        	WHERE record_name = neighborhood_study||': '||commitment_site
        )::numeric as units_gross,
        NULL as date,
        NULL as date_type,
		NULL::numeric as portion_built_by_2025,
		NULL::numeric as portion_built_by_2035,
		NULL::numeric as portion_built_by_2055,
        ST_UNION(b.wkb_geometry) as geom
    FROM dcp_n_study a
    LEFT JOIN  dcp_mappluto b
    ON a.bbl = b.bbl::bigint::text
    GROUP BY neighborhood_study, commitment_site
),
_esd_projects as (
    SELECT  
        'Empire State Development Projected Projects' as source,
        md5(array_to_string(array_agg(a.uid), '')) as record_id,
        array_agg(a.uid) as record_id_input,
        a.project_name as record_name,
        'Projected' as status,
        NULL as type,
        total_units::numeric as units_gross,
        NULL as date,
        NULL as date_type,
        NULL::numeric as portion_built_by_2025,
        NULL::numeric as portion_built_by_2035,
        NULL::numeric as portion_built_by_2055,
        ST_UNION(b.wkb_geometry) as geom
    FROM esd_projects a
    LEFT JOIN dcp_mappluto b
    ON a.bbl::numeric = b.bbl::numeric
    GROUP BY project_name, total_units
),
_hpd_pc as (
    SELECT 
        'HPD Projected Closings' as source,
        a.uid as record_id,
        array_agg(a.uid) as record_id_input,
        house_number||' '||street_name as record_name,
        'Projected' as status,
        NULL as type,
        ((min_of_projected_units::INTEGER + 
            max_of_projected_units::INTEGER)/2
        )::integer as units_gross,
        NULL as date,
        NULL as date_type,
        null::numeric as portion_built_by_2025,
        null::numeric as portion_built_by_2035,
        null::numeric as portion_built_by_2055,
        ST_UNION(b.wkb_geometry) as geom
    FROM hpd_pc a
    LEFT JOIN dcp_mappluto b
    ON a.bbl::numeric = b.bbl::numeric
    GROUP BY uid, house_number, street_name, 
    min_of_projected_units, max_of_projected_units
),
_hpd_rfp as (
    SELECT 
        'HPD RFPs' AS source,
        md5(array_to_string(array_agg(a.uid), '')) AS record_id,
        array_agg(a.uid) AS record_id_input,
        request_for_proposals_name AS record_name,
        (CASE 
            WHEN designated = 'Y' AND closed = 'Y' 
                THEN 'RFP designated; financing closed'
            WHEN designated = 'Y' AND closed = 'N' 
                THEN 'RFP designated; financing not closed'
            WHEN designated = 'N' AND closed = 'N' 
                THEN 'RFP issued; financing not closed'
        END) AS status,
        NULL AS type,
        (CASE 
            WHEN est_units ~* '-' THEN NULL 
            ELSE REPLACE(est_units, ',', '') 
        END)::integer AS units_gross,
        (CASE 
            WHEN closed_date = '-' THEN NULL 
            ELSE TO_CHAR(closed_date::date, 'YYYY/MM') 
        END) AS date,
        'Month Closed' AS date_type,
        (CASE WHEN likely_to_be_built_by_2025 = 'Y' 
            THEN 1 ELSE 0 END)::numeric AS portion_built_by_2025,
        (CASE WHEN likely_to_be_built_by_2025 = 'Y' 
            THEN 0 ELSE NULL END)::numeric AS portion_built_by_2035,
        (CASE WHEN likely_to_be_built_by_2025 = 'Y' 
            THEN 0 ELSE NULL END)::numeric AS portion_built_by_2055,
        st_union(b.wkb_geometry) AS geom
    FROM hpd_rfp a
    LEFT JOIN dcp_mappluto b
    ON a.bbl::numeric = b.bbl::numeric
    GROUP BY request_for_proposals_name, designated, 
    closed, est_units, closed_date, likely_to_be_built_by_2025
)
SELECT * FROM _dcp_n_study 				UNION
SELECT * FROM _dcp_n_study_future 		UNION
SELECT * FROM _dcp_n_study_projected 	UNION
SELECT * FROM _esd_projects 			UNION
SELECT * FROM _hpd_pc 					UNION
SELECT * FROM _hpd_rfp;