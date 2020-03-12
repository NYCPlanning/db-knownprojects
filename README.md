# db-knownprojects
Known project database -- data engineering

## Building Preparation:
1. `cd knownprojects_build` navigate to the building directory
2. `chmod u+x <name>.sh` to have the execute flag on for each shell script

## Building Instructions:
1. `./01_dataloading.sh` to load all source data into the postgresDB container
2. `./02_build.sh` to build Known Project database
3. `./03_dedupe.sh` to remove duplications across datasets
4. `./04_export.sh` to export the finalized Known Projects Housing database
5. `./05_qaqc.sh` to output the QAQC tables
6. `./06_archive.sh` to archive the Known Project database to EDM postgresDB