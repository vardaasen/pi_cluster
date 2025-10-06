#!/usr/bin/env bash
# shellcheck source=./messages.sh
. ./messages.sh
# shellcheck source=./logging.sh
. ./logging.sh
log_init
# shellcheck source=./cluster.data
DATA_FILE="cluster.data"
if [ ! -f "$DATA_FILE" ]; then
    log_error "Error: Data file '$DATA_FILE' not found. Please run 'generate_data.sh' first."
    exit 1
fi
. "$DATA_FILE"

stop_cluster() {
    local alias_var
    local alias
    log_info "Stoping Kafka cluster on all $NODE_COUNT nodes..."

    for (( i=1; i<=NODE_COUNT; i++ )); do
        alias_var="NODE_${i}_ALIAS"
        alias="${!alias_var}"
        log_info "  -> Stopping Kafka on $alias"
        ssh "$alias" 'docker compose down' &
        check_error
    done

    wait
    log_info "Cluster nodes stopped."
}
stop_cluster
