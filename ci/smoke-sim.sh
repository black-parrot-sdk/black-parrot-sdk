#!/bin/bash

# get common functions
source $(dirname $0)/common/functions.sh
bsg_log_info "starting $(basename $0)"

# check for binaries in path
bsg_check_var "BP_INSTALL_DIR"
bsg_log_info "setting installation directory as ${BP_INSTALL_DIR}"
# check for programs in path
bsg_check_var "BP_RISCV_DIR"
bsg_log_info "setting installation directory as ${BP_RISCV_DIR}"

_bsg_parse_args 3 sim suite prog "$1" "$2" "$3"

# find test components 
SIM_PATH=$(find "${BP_INSTALL_DIR}/bin" -name "${_sim}")
PROG_PATH=$(find "${BP_RISCV_DIR}/${_suite}" -name "${_prog}")
bsg_log_info "sim found at ${SIM_PATH}"
bsg_log_info "program found at ${PROG_PATH}"

# do the actual job
SIM_CMD="${SIM_PATH} --ncpus=1 ${PROG_PATH}"
bsg_run_task "executing ${PROG} with ${SIM}" ${SIM_CMD}

# pass if no error
bsg_pass $(basename $0)
