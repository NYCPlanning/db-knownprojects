# db-knownprojects

This repo contains code for creating the Known Projects Database (KPDB). The build process has multiple automated phases, separated by manual review. For detailed information on the tables created throughout the build process, see the [build environment table descriptions](https://github.com/NYCPlanning/db-knownprojects/wiki/Build-environment-tables).

## Instructions: 
### Build:
- Load data: `./01_dataloading.sh`
- Build database: `./02_build.sh`
- Export: `./03_export.sh`

### Development:
1. Pulling repo for the first time and pull files from submodule
```
git submodule update --init --recursive
```
2. Updating submodule
```
git submodule update --remote
```
