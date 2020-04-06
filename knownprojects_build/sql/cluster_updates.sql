-- Update cluster table with manual edits
UPDATE clusters."2019" a
SET sub_cluster_id = b.sub_cluster_id
FROM reviewed_clusters."2019" b
WHERE a.source = b.source
AND a.project_id = b.project_id
AND a.project_name = b.project_name;
