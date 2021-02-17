# db-knownprojects

This repo contains code for creating the Known Projects Database (KPDB). The build process has multiple automated phases, separated by manual review. For detailed information on the tables created throughout the build process, see the [build environment table descriptions](https://github.com/NYCPlanning/db-knownprojects/wiki/Build-environment-tables).

## Instructions: 
1. Pulling repo for the first time and pull files from submodule
```
git submodule update --init --recursive
```
2. Updating submodule
```
git submodule update --remote
```

First automated phase: 
+ [01_dataloading](https://github.com/NYCPlanning/db-knownprojects/blob/master/knownprojects_build/01_dataloading.sh)
+ [02_build_source_tables](https://github.com/NYCPlanning/db-knownprojects/blob/master/knownprojects_build/02_build_source_tables.sh)
+ [03.1_clusters](https://github.com/NYCPlanning/db-knownprojects/blob/master/knownprojects_build/03.1_clusters.sh)

First review phase: [cluster review](https://github.com/NYCPlanning/db-knownprojects/wiki/Cluster-review-process)

Second automated phase:
+ [03.2_housing](https://github.com/NYCPlanning/db-knownprojects/blob/master/knownprojects_build/03.2_housing.sh)

Second review phase: [DOB match review](https://github.com/NYCPlanning/db-knownprojects/wiki/DOB-review-process)

Third automated phase:
+ [04_build_kpbd](https://github.com/NYCPlanning/db-knownprojects/blob/master/knownprojects_build/04_build_kpdb.sh)

Third review phase: [Corrections review](https://github.com/NYCPlanning/db-knownprojects/wiki/KPDB-corrections-process:-in-depth-research)

Fourth automated phase:
+ [05_corrections](https://github.com/NYCPlanning/db-knownprojects/blob/master/knownprojects_build/05_corrections.sh) 

NOTE:
For 2020 release, reruns of 05_corrections must get run on kpdb."2020_05_29":

```sql
/** APPLY NEW ROUND OF CORRECTIONS **/

-- First run:
DELETE FROM kpdb."2020";

INSERT INTO kpdb."2020"
SELECT * FROM kpdb."2020_05_29";

-- Then: Rerun 05_corrections.sh
```

See checks in [qaqcmanual.sql](https://github.com/NYCPlanning/db-knownprojects/blob/qaqcmanualreview/knownprojects_build/sql/qaqcmanual.sql)
