#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=linux
prog=linux

for N in 1 2 4; do
    do_single_sim ${sim} ${suite} ${prog}-$N $N
done

bsg_pass $(basename $0)

