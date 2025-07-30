#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=bp-demos
progs=(lfs_demo sample)

for prog in "${progs[@]}"; do
    do_single_sim ${sim} ${suite} ${prog}
done

bsg_pass $(basename $0)

