#!/bin/bash
source $(dirname $0)/functions.sh

sim=$1; shift

suite=riscv-dv
progs=(riscv_amo_test riscv_arithmetic_basic_test riscv_floating_point_arithmetic_test riscv_floating_point_mmu_stress_test riscv_floating_point_rand_test riscv_full_interrupt_test riscv_hint_instr_test riscv_invalid_csr_test riscv_jump_stress_test riscv_loop_test riscv_machine_mode_rand_test riscv_mmu_stress_test riscv_no_fence_test riscv_non_compressed_instr_test riscv_pmp_test riscv_privileged_mode_rand_test riscv_rand_instr_test riscv_rand_jump_test riscv_unaligned_load_store_test)

#for K in $(seq 1 19); do
for K in $(seq 1 1); do
	for prog in "${progs[@]}"; do
    	do_single_sim ${sim} ${suite} ${prog}_$K 1
	done
done

bsg_pass $(basename $0)

