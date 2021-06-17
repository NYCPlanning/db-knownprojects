#!/bin/bash
source config.sh

max_bg_procs 5
archive public.kpdb kpdb.kpdb &
archive public.combined facdb.combined &
archive public.review_dob facdb.review_dob &
archive public.review_project facdb.review_project
archive public.corrections_applied facdb.corrections_applied &
archive public.corrections_not_applied facdb.corrections_not_applied &
wait
echo "archive complete"