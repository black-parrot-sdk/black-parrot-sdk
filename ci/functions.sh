#!/bin/bash

# source-only guard
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && return
# include guard
[ -n "${_LOCAL_SH_INCLUDE}" ] && return

# disable automatic export
set -o allexport

# constants
readonly _LOCAL_SH_INCLUDE=1

# runs a single simulation and exits on failure
# usage: do_single_sim dromajo beebs aha-compress 1
do_single_sim() {
    _bsg_parse_args 4 sim suite prog cores "$1" "$2" "$3" "$4"

    echo "sim: ${_sim} suite: ${_suite} prog: ${_prog} cores: ${_cores}"

    # find test components 
    SIM_PATH=$(find "${BP_INSTALL_DIR}/bin" -name "${_sim}")
    PROG_PATH=$(find "${BP_RISCV_DIR}/${_suite}" -name "${_prog}.riscv")
    bsg_log_info "sim found at ${SIM_PATH}"
    bsg_log_info "program found at ${PROG_PATH}"

    if [[ "${_sim}" == "dromajo" ]]; then
        CORES_FLAG="--ncpus=${_cores}"
    elif [[ "${_sim}" == "spike" ]]; then
        CORES_FLAG="-p${_cores}"
    else
        CORES_FLAG=""
    fi

    # do the actual job
    SIM_CMD="${SIM_PATH} ${CORES_FLAG} ${PROG_PATH}"
    bsg_run_task "executing ${_prog} with ${_sim}" ${SIM_CMD}
    bsg_sentinel_fail '.*CORE.*FSH.*FAIL'
    bsg_sentinel_cont '.*CORE.*FSH.*PASS'
}

# check for binaries in path
bsg_check_var "BP_INSTALL_DIR"
bsg_log_info "setting installation directory as ${BP_INSTALL_DIR}"
bsg_log_info "setting program directory as ${BP_RISCV_DIR}"
bsg_check_var "BP_RISCV_DIR"
PATH=${BP_INSTALL_DIR}/bin:${PATH}

# disable automatic export
set +o allexport

