#!/bin/bash
source config.sh
psql $BUILD_ENGINE -f sql/append_planner_added.sql