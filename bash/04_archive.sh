#!/bin/bash
source bash/config.sh

max_bg_procs 5
archive public.kpdb kpdb.kpdb &
archive public.combined kpdb.combined &
archive public.review_dob kpdb.review_dob &
archive public.review_project kpdb.review_project
archive public.corrections_applied kpdb.corrections_applied &
archive public.corrections_not_applied kpdb.corrections_not_applied &
wait
echo "archive complete"