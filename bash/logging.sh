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
    local level=$1
    shift
    local format=$1
    shift
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S,%N000%z")
    
    # Use -- to signal the end of options to printf
    printf -- "${timestamp} [%s] " "$level"
    printf -- "$format" "$@"
    printf "\n"
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
        log_error "%s (exit code: %d): %s\n" "$message" "$exit_code" "$failed_command"
        exit $exit_code
    fi
}
