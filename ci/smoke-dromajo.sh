#!/bin/bash
source $(dirname $0)/functions.sh

# do the actual job
bsg_run_task "finding dromajo" which dromajo
bsg_sentinel_fail "which: no"

# pass if no error
bsg_pass $(basename $0)

