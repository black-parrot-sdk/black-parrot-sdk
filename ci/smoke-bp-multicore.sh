#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=bp-tests
progs=(mc_work_share_sort mc_amo_add mc_lrsc_add mc_rand_walk mc_sanity mc_template)

for N in 1 2 4 8 16; do
    for prog in "${progs[@]}"; do
        do_single_sim ${sim} ${suite} ${prog} $N
    done
done

bsg_pass $(basename $0)

