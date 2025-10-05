#!/usr/bin/env bash

LOG_FILE=${LOG_FILE:-"./logs/pi_cluster.log"}
LOG_LEVEL=${LOG_LEVEL:-INFO}
LOG_STDOUT=${LOG_STDOUT:-true}

declare -A _LOG_LEVELS
_LOG_LEVELS=([ERROR]=0 [WARN]=1 [INFO]=2 [DEBUG]=3)

log_init() {
    mkdir -p "$(dirname "$LOG_FILE")"
}

log_emit() {
    local level
    local fmt
    local wanted
    local actual
    local ts
    local msg

    level=$1; shift
    fmt=$1; shift
    wanted=${_LOG_LEVELS[$LOG_LEVEL]:-2}
    actual=${_LOG_LEVELS[$level]:-2}

    (( actual > wanted )) && return 0

    ts=$(date -Ins)
    msg=$(printf "$fmt" "$@")
    printf "%s [%s] %s\n" "$ts" "$level" "$msg" >>"$LOG_FILE"
    [ "$LOG_STDOUT" = true ] && printf "%s [%s] %s\n" "$ts" "$level" "$msg"
}

log_error(){ log_emit ERROR "$@"; }
log_warn(){ log_emit WARN "$@"; }
log_info(){ log_emit INFO "$@"; }
log_debug(){ log_emit DEBUG "$@"; }

# This function checks the exit code of the last command.
# If it's not 0 (success), it logs an error and exits.
# Usage: check_error "Your custom error message"
check_error() {
    local exit_code
    local failed_command
    local message
    exit_code=$?
    failed_command=$BASH_COMMAND
    message=${1:-"Command failed"}
    if [ $exit_code -ne 0 ]; then
	    log_error "%s (exit %d) %s\n" "$message" "$exit_code" "$failed_command" >&2
        exit $exit_code
    fi
}
