#!/bin/bash
source config.sh

psql $BUILD_ENGINE -1 -f _sql/dcp_application.sql