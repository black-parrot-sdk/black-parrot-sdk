
######################
# bookkeeping start
######################

# source-only guard
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && return
# include guard
[ -n "${_COMMON_SH_INCLUDE}" ] && return

# enable automatic export
set -o allexport

# enable unofficial bash strict mode
set -eo pipefail
IFS=$'\n\t'

######################
# global variables
######################

# constants
readonly _COMMON_SH_INCLUDE=1

readonly _BSG_HDR_RAW="\t"
readonly _BSG_HDR_ERR="[BSG-ERR]"
readonly _BSG_HDR_WRN="[BSG-WRN]"
readonly _BSG_HDR_INF="[BSG]"
readonly _BSG_HDR_DBG="[BSG-DBG]"

readonly _BSG_HDR_PASS="[BSG-PASS]"
readonly _BSG_HDR_FAIL="[BSG-FAIL]"

readonly _BSG_E_LOG_LEVEL_MIN=-99
readonly _BSG_E_LOG_LEVEL_RAW=-1
readonly _BSG_E_LOG_LEVEL_ERR=0
readonly _BSG_E_LOG_LEVEL_WRN=1
readonly _BSG_E_LOG_LEVEL_INF=2
readonly _BSG_E_LOG_LEVEL_DBG=3
readonly _BSG_E_LOG_LEVEL_MAX=99

# defaults
_BSG_LOG_LEVEL=-1
_BSG_LOG_INIT=0
_BSG_TRIM_LINES=5
_BSG_LOG_FILE=/dev/null
_BSG_RPT_FILE=/dev/null

######################
# helper functions
######################
# desc: non-fancy argparser this will set _arg1="val1", _arg2="val2", etc.
# usage: _bsg_check_args N arg1 arg2 ... $@
# caveats: no optional arguments or nested functions
_bsg_parse_args() {
    local N="$1"
    local vars=("${@:2:$(($N))}")
    local vals=("${@:$(($N+2)):$((2*$N+2))}")

    if [[ "${#vals[@]}" -ne $N ]]; then
        local call="${FUNCNAME[1]}"
        printf "usage: ${call} ${vars[*]}\n"
        return 1
    fi

    for i in "${!vars[@]}"; do
        eval _${vars[i]}=\"${vals[i]}\"
    done
}

# desc: print formatter
# usage: _bsg_log_level()
_bsg_log_level() {
    local _arg="$1"
    local _level="$2"

    if [ "${_BSG_LOG_INIT}" -ne 1 ]; then
        printf "[CI-WRN]: logging not initialized...\n"
    fi

    if [ "${_BSG_LOG_LEVEL}" -ge "${_level}" ]; then
        printf "${_arg}\n"
    fi
}

######################
# user functions
######################
bsg_log_init() {
    _bsg_parse_args 3 logfile rptfile loglevel $@

    printf "${_BSG_HDR_RAW} initializing logging...\n"
    if [ "${_BSG_LOG_INIT}" -eq 1 ]; then
        printf "error: logging already initialized"
        return 1
    fi

    mkdir -p $(dirname ${_logfile}) $(dirname ${_rptfile})
    if [ -f "${_logfile}.0" ]; then
        suffix=$(stat ${_logfile}.* --printf "%i\n" | wc -l)
    else
        suffix=0
    fi

    _BSG_LOG_FILE="${_logfile}.${suffix}"
    _BSG_RPT_FILE="${_rptfile}.${suffix}"
    _BSG_LOG_LEVEL="${_loglevel}"
    _BSG_LOG_INIT=1

    bsg_log_raw "logfile: ${_BSG_LOG_FILE} with log level ${_BSG_LOG_LEVEL}"
    bsg_log_raw "loglevel: ${_BSG_LOG_LEVEL}"
    bsg_log_raw "rptfile: ${_BSG_RPT_FILE}"
}

bsg_log() {
    _bsg_parse_args 1 str "$@" || return 1

    _bsg_log_level "${_BSG_HDR_INF} ${_str}" ${_BSG_E_LOG_LEVEL_MIN}
}

bsg_log_raw() {
    _bsg_parse_args 1 str "$@" || return 1

    _bsg_log_level "${_BSG_HDR_RAW} ${_str}" ${_BSG_E_LOG_LEVEL_MIN}
}

bsg_log_error() {
    _bsg_parse_args 1 str "$@" || return 1

    _bsg_log_level "${_BSG_HDR_ERR} ${_str}" ${_BSG_E_LOG_LEVEL_ERR}
}

bsg_log_warn() {
    _bsg_parse_args 1 str "$@" || return 1

    _bsg_log_level "${_BSG_HDR_WRN} ${_str}" ${_BSG_E_LOG_LEVEL_WRN}
}

bsg_log_info() {
    _bsg_parse_args 1 str "$@" || return 1

    _bsg_log_level "${_BSG_HDR_INF} ${_str}" ${_BSG_E_LOG_LEVEL_INF}
}

bsg_log_debug() {
    _bsg_parse_args 1 str "$@" || return 1

    _bsg_log_level "${_BSG_HDR_DBG} ${_str}" ${_BSG_E_LOG_LEVEL_DBG}
}

bsg_check_var() {
    _bsg_parse_args 1 var "$@" || return 1

    if [ -z "${!_var}" ] || [ "${!_var}" == "setme" ]; then
        printf "${_var} is unset: ${!_var}\n"
        return 1
    fi

    printf "\t${_var}=${!_var}\n"
}

# runs an arbitrary command with a CI wrapper
# usage: bsg_run_task desc cmd <opts>
bsg_run_task() {
    _desc="$1"; shift; _cmd="$@"

    bsg_log_info "running task..."
    bsg_log_raw "description: ${_desc}"
    bsg_log_raw "command: ${_cmd}"
    bsg_log_raw "output:"

    set -o pipefail
    {
        # Run the command and format output
        eval "$_cmd" 2>&1 | sed 's/^/\t\t/g' | tee -a "${_BSG_LOG_FILE}" | head -n"${_BSG_TRIM_LINES}"
        _exit_code=$?
    }
    set +o pipefail
    bsg_log_raw "...truncated after ${_BSG_TRIM_LINES} lines"

    if [ $_exit_code -ne 0 ]; then
        bsg_log_error "task returned non-zero: $_exit_code"
    fi

    return $_exit_code
}

bsg_pass() {
    _bsg_parse_args 1 str "$@" || return 1

    printf "${_BSG_HDR_PASS} ${_str}\n"
}

bsg_fail() {
    _bsg_parse_args 1 str "$@" || return 1

    printf "${_BSG_HDR_FAIL} ${_str}\n"
}

######################
# bookkeeping end
######################

# disable automatic export
set +o allexport

