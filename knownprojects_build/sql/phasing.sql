-- DOB
UPDATE combined_ADtest
SET    portion_built_by_2025 = CASE WHEN status = 'Permit issued' OR status = 'Filed' OR status LIKE 'In progress%' THEN 1 ELSE NULL END
     , portion_built_by_2035 = CASE WHEN status <> 'Withdrawn' AND inactive = 1 THEN 1 ELSE NULL END
     , phasingknown = 0
WHERE source = 'DOB';
-- HPD Projected Closings
UPDATE combined_ADtest
SET    portion_built_by_2025 = CASE WHEN date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) <= 5 THEN 1 ELSE NULL END
     , portion_built_by_2035 = CASE WHEN date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) > 5 AND date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) <= 10 THEN 1 ELSE NULL END
     , portion_built_by_2055 = CASE WHEN date_part('year',age(to_date((CONCAT(RIGHT(date,4)::numeric+3,'-06-30')),'YYYY-MM-DD'),CURRENT_DATE)) > 10 THEN 1 ELSE NULL END
     , phasingknown = 1
WHERE source = 'HPD Projected Closings';
-- HPD RFPs
UPDATE combined_ADtest
SET    portion_built_by_2025 = 1
     , phasingknown = 1
WHERE source = 'HPD RFPs';
-- EDC
UPDATE combined_ADtest
SET    portion_built_by_2025 = CASE WHEN date::numeric <= date_part('year', CURRENT_DATE)+5 THEN 1 ELSE NULL END
     , portion_built_by_2035 = CASE WHEN date::numeric > date_part('year', CURRENT_DATE)+5 AND date::numeric <= date_part('year', CURRENT_DATE)+10 THEN 1 ELSE NULL END
     , portion_built_by_2055 = CASE WHEN date::numeric > date_part('year', CURRENT_DATE)+10 THEN 1 ELSE NULL END
     , phasingknown = 1
WHERE source = 'EDC Projected Projects';
-- DCP Application
UPDATE combined_ADtest
SET   portion_built_by_2035 = 1 
     , phasingknown = 0
WHERE source = 'DCP Application' AND status <> 'Record Closed';
-- Neighborhood Study Projected Development Sites (work in progress)
WITH counting AS (
    SELECT RIGHT('9/7/2017',4)::numeric+3 as startyear,
        RIGHT('9/7/2017',4)::numeric+10 as endyear
)

UPDATE combined_ADtest
SET   portion_built_by_2035 = 
     , phasingknown = 0
WHERE source = 'Neighborhood Study Projected Development Sites';
-- Future Neighborhood Studies
UPDATE combined_ADtest
SET   portion_built_by_2035 = CASE WHEN record_name LIKE 'Gowanus%' THEN round(1/3::numeric,2) ELSE .5 END
      portion_built_by_2055 = CASE WHEN record_name LIKE 'Gowanus%' THEN round(2/3::numeric,2) ELSE .5 END
     , phasingknown = 0
WHERE source = 'Future Neighborhood Studies';