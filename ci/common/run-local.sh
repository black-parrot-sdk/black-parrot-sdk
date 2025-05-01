#!/bin/bash

# get common functions
source $(dirname $0)/functions.sh

# initializing logging
export JOB_LOG="/tmp/ci-local-log/myjob.log"
export JOB_RPT="/tmp/ci-local-rpt/myjob.rpt"
export JOB_LOGLEVEL="3"
bsg_log_init ${JOB_LOG} ${JOB_RPT} ${JOB_LOGLEVEL} || exit 1

bsg_log_info "running ci locally"
bsg_log_raw "with arguments: $*"

# Check if there are no arguments
if [ "$#" -eq 0 ]; then
	bsg_log_error "no script specified"
	bsg_log_raw "usage: run-local.sh <ci-script.sh>"
	exit 1
fi

bsg_log_info "setting common variables"
export REPO_NAME="black-parrot-sdk"
export BP_INSTALL_DIR="$(git rev-parse --show-toplevel)/install"
export BP_RISCV_DIR="$(git rev-parse --show-toplevel)/riscv"

bsg_log_info "checking common variables"
bsg_check_var "REPO_NAME" || exit 1
bsg_check_var "JOB_LOG" || exit 1
bsg_check_var "JOB_RPT" || exit 1

exec "$@"

