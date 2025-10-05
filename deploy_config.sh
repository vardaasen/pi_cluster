#!/usr/bin/env bash
# shellcheck source=./regexp_lib.sh
. ./regexp_lib.sh
# shellcheck source=./messages.sh
. ./messages.sh
# shellcheck source=./logging.sh
. ./logging.sh
log_init

DATA_FILE="cluster.data"
project_conf="project.conf"
COMPOSE_FILE="docker-compose.yml"

validate_data() {
    local actual_node_count
    local alias_var
    local ip_var
    local i

    log_info "$INFO_VALIDATING_DATA" "$DATA_FILE"
    if [ ! -f $DATA_FILE ]; then
        log_error "${ERROR_DATA_FILE_NOT_FOUND}"
        exit 1
    fi
    # shellcheck source=./cluster.data
    . "$DATA_FILE"
    check_error
    : "${NODE_COUNT:?$(log_error "${ERROR_NODE_COUNT_INVALID}")}"

    actual_node_count=0
    for var_name in $(declare -p | sed -n "$SED_PATTERN_EXTRACT_VAR_NAME"); do
        if [[ "$var_name" =~ $GREP_PATTERN_NODE_ALIAS_VAR ]]; then
            actual_node_count=$((actual_node_count + 1))
        fi
    done

    if [ "$NODE_COUNT" -ne "$actual_node_count" ]; then
        log_error "${ERROR_DATA_INCONSISTENT}" "${NODE_COUNT}" "${actual_node_count}"
        exit 1
    fi

    for (( i=1; i<=NODE_COUNT; i++ )); do
        alias_var="NODE_${i}_ALIAS"
        ip_var="NODE_${i}_IP"
        if [ -z ${!alias_var} ]; then
            log_error "$ERROR_DATA_INCOMPLETE" "$i" "$alias_var"
            exit 1
        fi
        if [ -z ${!ip_var} ]; then
            log_error "$ERROR_DATA_INCOMPLETE" "$i" "$ip_var"
            exit 1
        fi
    done
    log_info "${SUCCESS_VALIDATION}"
}

distribute_files() {
    local alias_var
    local alias

    log_info "$INFO_DISTRIBUTING_FILES"
    for (( i=1; i<=NODE_COUNT; i++ )); do
        alias_var="NODE_${i}_ALIAS"
        alias="${!alias_var}"
        log_info "$INFO_COPYING_FILE" "$COMPOSE_FILE" "$alias"
        scp "./$COMPOSE_FILE" "$alias:~/"
        check_error
    done
}

configure_node() {
    local node_id
    local computer_ip
    local is_dry_run
    local alias_var
    local ip_var
    local alias
    local ip
    local daemon_json_content
    local env_content

    node_id="$1"
    computer_ip="$2"
    is_dry_run="$3"

    alias_var="NODE_${node_id}_ALIAS"
    ip_var="NODE_${node_id}_IP"
    alias="${!alias_var}"
    ip="${!ip_var}"
    log_info "$INFO_CONFIGURING_NODE" "Now" "$node_id" "$alias" "$ip"

    daemon_json_content=$(cat  <<EOF
{
  "registry-mirrors": ["http://${computer_ip}:5000"],
  "insecure-registries": ["${computer_ip}:5000"] 
}
EOF
    check_error

)
    env_content=$(cat <<EOF
# --- Node-Specific yaml configuration ---
KAFKA_CFG_NODE_ID=${node_id}
KAFKA_CFG_ADVERTISED_LISTENERS=INTERNAL://kafka:9091,EXTERNAL://${ip}:9092

# --- Shared Cluster yaml configuration ---
KAFKA_CFG_CLUSTER_ID=${KAFKA_CFG_CLUSTER_ID}
KAFKA_CFG_PROCESS_ROLES=${KAFKA_CFG_PROCESS_ROLES}
KAFKA_CFG_CONTROLLER_LISTENER_NAMES=${KAFKA_CFG_CONTROLLER_LISTENER_NAMES}
KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=${KAFKA_QUORUM_VOTERS}
KAFKA_CFG_LISTENERS=${KAFKA_CFG_LISTENERS}
KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP}
KAFKA_CFG_INTER_BROKER_LISTENER_NAME=${KAFKA_CFG_INTER_BROKER_LISTENER_NAME}
KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=${KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR}
KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=${KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR}
KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR=${KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR}
ALLOW_PLAINTEXT_LISTENER=${ALLOW_PLAINTEXT_LISTENER}
EOF
)
    check_error

    if [ "$is_dry_run" = true ]; then
        log_info "DRY RUN: Would write daemon.json to $alias"
        log_info "DRY RUN: Would write .env file to $alias"
        log_info "DRY RUN: Would restart docker on $alias"
    else
        ssh "$alias" "echo '${daemon_json_content}' | sudo tee /etc/docker/daemon.json > /dev/null" && \
        ssh "$alias" "echo '${env_content}' > .env" && \
        ssh "$alias" 'sudo systemctl restart docker' && \
        log_info "$INFO_CONFIGURING_NODE_COMPLETE" "$alias"
    fi
}

main() {
    local dry_run
    local computer_ip

    dry_run=false
    if [[ "$1" == "--dry-run" ]]; then
        dry_run=true
        log_info "$INFO_DRY_RUN_STARTED"
    fi
    if [ ! -f "$project_conf" ]; then
        log_error "Project config '$project_conf' not found. Please run the main menu script first."
        exit 1
    fi
    . "$project_conf"
    check_error

    validate_data

    computer_ip=$(ipconfig getifaddr "$NETWORK_INTERFACE")
    check_error
    if [ -z "$computer_ip" ]; then
        log_error "${ERROR_NO_IP_FOR_INTERFACE}" "$NETWORK_INTERFACE"
        exit 1
    fi

    . "$DATA_FILE"
    check_error
    # each node receive a docker-compose.yaml
    distribute_files

    log_info "$INFO_STARTING_CONFIGURATION" "$NODE_COUNT"
    for (( i=1; i<=NODE_COUNT; i++ )); do
        # Run the configure_node() in the background for each node.
        configure_node "$i" "$computer_ip" "$dry_run" &
    done
    # wait for all nodes
    wait
    if [ "$dry_run" = true ]; then
        log_info "$INFO_DRY_RUN_COMPLETE"
    else
        log_info "${SUCCESS_DEPLOYMENT_COMPLETE}"
    fi
}

main "$@"
