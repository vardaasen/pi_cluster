#!/usr/bin/env bash
set -e
# shellcheck source=./messages.sh
. ./messages.sh
# shellcheck source=./logging.sh
. ./logging.sh
log_init
# shellcheck source=./cluster.data
DATA_FILE="cluster.data"
if [ ! -f "$DATA_FILE" ]; then
    log_error "$ERROR_DATA_FILE_NOT_FOUND"
    exit 1
fi
. "$DATA_FILE"

# This function checks for consistency and starts a single node
check_and_start_node() {
    local node_id="$1"
    local alias_var="NODE_${node_id}_ALIAS"
    local alias="${!alias_var}"

    log_info "-> Preparing to start Kafka on %s" "$alias"

    ssh "$alias" "$(declare -f log_emit log_info log_error)" '
        set -e

        cd ~/
        log_info "  -> Starting Kafka container on %s..." "$HOSTNAME"
        docker compose up -d

        EXPECTED_ID=$(grep "KAFKA_CLUSTER_ID" docker-compose.yml | awk -F= "{print \$2}" | tr -d " ")
        if [ -z "$EXPECTED_ID" ]; then
            log_error "Could not find KAFKA_CLUSTER_ID in docker-compose.yml on this node."
            docker compose down # Clean up
            exit 1
        fi

        PROJECT_NAME=$(docker compose ls -q)
        VOLUME_NAME="${PROJECT_NAME}_kafka_data"

        if docker volume inspect "$VOLUME_NAME" &> /dev/null; then
            META_FILE_PATH=$(docker volume inspect "$VOLUME_NAME" -f "{{.Mountpoint}}")/_data/meta.properties
            if [ -f "$META_FILE_PATH" ]; then
                STORED_ID=$(grep "cluster.id" "$META_FILE_PATH" | cut -d= -f2)
                if [ "$EXPECTED_ID" != "$STORED_ID" ]; then
                    log_error "Cluster ID mismatch! Data volume is stale."
                    docker compose down # Clean up
                    exit 1
                fi
            fi
        else
            log_error "Could not find the data volume '$VOLUME_NAME'. Check Docker."
            docker compose down # Clean up
            exit 1
        fi

        log_info "  -> Cluster ID is consistent for %s." "$HOSTNAME"
    '
    check_error
}

main() {
    local alias
    local alias_var
    local ip_var
    local ip

    log_info "$TUI_STARTING_CLUSTER"

    for (( i=1; i<=NODE_COUNT; i++ )); do
        check_and_start_node "$i" &
    done

    wait
    log_info "$TUI_CLUSTER_STARTED"
}
main
