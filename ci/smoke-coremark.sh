#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=coremark
progs=(coremark)

for prog in "${progs[@]}"; do
    do_single_sim ${sim} ${suite} ${prog} 1
done

bsg_pass $(basename $0)

