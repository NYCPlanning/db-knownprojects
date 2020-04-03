-- Update cluster table with manual edits
UPDATE clusters
SET sub_cluster_id = b.sub_cluster_id
FROM reviewed_clusters b
WHERE source = b.source
AND project_id = b.project_id
AND project_name = b.project_name;
