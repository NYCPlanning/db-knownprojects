-- DOB
UPDATE kpdb."2020"
SET    prop_within_5_years = CASE WHEN status ~* 'Permit issued|Filed|In progress' AND inactive <> '1' THEN 1 ELSE NULL END
     , prop_5_to_10_years = CASE WHEN status <> 'Withdrawn' AND inactive = '1' THEN 1 ELSE NULL END
     , phasing_known = 0
WHERE source = 'DOB';

-- HPD Projected Closings
UPDATE kpdb."2020"
SET    prop_within_5_years = CASE WHEN date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) <= 5 THEN 1 ELSE NULL END
     , prop_5_to_10_years = CASE WHEN date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) > 5 AND date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) <= 10 THEN 1 ELSE NULL END
     , prop_after_10_years = CASE WHEN date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) > 10 THEN 1 ELSE NULL END
     , phasing_known = 1
WHERE source = 'HPD Projected Closings';

-- HPD RFPs
UPDATE kpdb."2020"
SET    prop_within_5_years = 1
     , phasing_known = 1
WHERE source = 'HPD RFPs';

-- EDC
UPDATE kpdb."2020"
SET    prop_within_5_years = CASE WHEN date::numeric <= date_part('year', CURRENT_DATE)+5 THEN 1 ELSE NULL END
     , prop_5_to_10_years = CASE WHEN date::numeric > date_part('year', CURRENT_DATE)+5 AND date::numeric <= date_part('year', CURRENT_DATE)+10 THEN 1 ELSE NULL END
     , prop_after_10_years = CASE WHEN date::numeric > date_part('year', CURRENT_DATE)+10 THEN 1 ELSE NULL END
     , phasing_known = 1
WHERE source = 'EDC Projected Projects';

-- DCP Application
UPDATE kpdb."2020"
SET   prop_5_to_10_years = 1 
     , phasing_known = 0
WHERE source = 'DCP Application' AND status <> 'Record Closed';

-- Neighborhood Study Projected Development Sites
WITH years as (
     SELECT record_id, generate_series(LEFT(date,4)::numeric+3, LEFT(date,4)::numeric+9) as yearspan
     FROM dcp_n_study_projected_proj),
yeargroups as (
     SELECT record_id,
          COUNT(*) as total,
          sum(case when yearspan <= date_part('year', CURRENT_DATE)+5 then 1 else 0 end)::numeric AS fiveyear,
          sum(case when yearspan > date_part('year', CURRENT_DATE)+5 AND yearspan <= date_part('year', CURRENT_DATE)+10 then 1 else 0 end)::numeric AS tenyear,
          sum(case when yearspan > date_part('year', CURRENT_DATE)+10 then 1 else 0 end)::numeric AS tenyearplus
     FROM years
     GROUP BY record_id)
UPDATE kpdb."2020" a
SET   prop_within_5_years = round(fiveyear/total,2)
     ,prop_5_to_10_years = round(tenyear/total,2)
     ,prop_after_10_years = round(tenyearplus/total,2)
     ,phasing_known = 0
FROM yeargroups b
WHERE a.record_id=b.record_id
AND source = 'Neighborhood Study Projected Development Sites'
AND record_name <> 'East New York';

WITH years as (
     SELECT record_id, generate_series(LEFT(date,4)::numeric+3, LEFT(date,4)::numeric+14) as yearspan
     FROM dcp_n_study_projected_proj),
yeargroups as (
     SELECT record_id,
          COUNT(*) as total,
          sum(case when yearspan <= date_part('year', CURRENT_DATE)+5 then 1 else 0 end)::numeric AS fiveyear,
          sum(case when yearspan > date_part('year', CURRENT_DATE)+5 AND yearspan <= date_part('year', CURRENT_DATE)+10 then 1 else 0 end)::numeric AS tenyear,
          sum(case when yearspan > date_part('year', CURRENT_DATE)+10 then 1 else 0 end)::numeric AS tenyearplus
     FROM years
     GROUP BY record_id)
UPDATE kpdb."2020" a
SET   prop_within_5_years = round(fiveyear/total,2)
     ,prop_5_to_10_years = round(tenyear/total,2)
     ,prop_after_10_years = round(tenyearplus/total,2)
     ,phasing_known = 0
FROM yeargroups b
WHERE a.record_id=b.record_id
AND source = 'Neighborhood Study Projected Development Sites'
AND record_name = 'East New York';

-- Future Neighborhood Studies
UPDATE kpdb."2020"
SET   prop_5_to_10_years = CASE WHEN record_name LIKE 'Gowanus%' THEN round(1/3::numeric,2) ELSE .5 END
     , prop_after_10_years = CASE WHEN record_name LIKE 'Gowanus%' THEN round(2/3::numeric,2) ELSE .5 END
     , phasing_known = 0
WHERE source = 'Future Neighborhood Studies';

-- Make sure proportions add up to 1
UPDATE kpdb."2020"
SET prop_within_5_years = (CASE WHEN (prop_5_to_10_years IS NULL 
                                   AND prop_after_10_years IS NULL) THEN NULL
                              ELSE 1-(COALESCE(prop_5_to_10_years::numeric, 0) + COALESCE(prop_after_10_years::numeric, 0))
                              END) 
WHERE prop_within_5_years IS NULL;

UPDATE kpdb."2020"
SET prop_5_to_10_years = (CASE WHEN (prop_within_5_years IS NULL
                                   AND prop_after_10_years IS NULL) THEN NULL
                              ELSE 1-(prop_within_5_years::numeric + COALESCE(prop_after_10_years::numeric,  0))
                              END)
WHERE prop_5_to_10_years IS NULL;

UPDATE kpdb."2020"
SET prop_after_10_years = (CASE WHEN (prop_within_5_years IS NULL
                                   AND prop_5_to_10_years IS NULL) THEN NULL
                              ELSE 1-(prop_within_5_years::numeric + prop_5_to_10_years::numeric)
                              END)
WHERE prop_after_10_years IS NULL;