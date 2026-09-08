#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=bp-tests
progs=(amo_nonblocking cache_flush cache_hammer constructor divide_hazard dram_stress fflags_haz fp_neg_zero_nanbox fp_precision hello_world loop mapping map mstatus_fs nanboxing paging satp_nofence stream_hammer template timer_interrupt interrupt_priority interrupt_priority_simultaneous interrupt_priority_race unwinding vector virtual out_of_bounds_test satp_u_mode pmp_s_mode mprv_u_page cycle_write gigapage_alignment pte_reserved counteren_u_mode)

# mprv_debug_page test does not pass in standalone testing due to https://github.com/black-parrot-sdk/black-parrot-sdk/issues/76

for prog in "${progs[@]}"; do
    do_single_sim ${sim} ${suite} ${prog} 1
done

bsg_pass $(basename $0)

