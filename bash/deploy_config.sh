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

configure_node() {
    local node_id
    local computer_ip
    local is_dry_run
    local alias_var
    local ip_var
    local alias
    local ip
    local compose_content

    node_id="$1"
    computer_ip="$2" # redundant?
    is_dry_run="$3"

    alias_var="NODE_${node_id}_ALIAS"
    ip_var="NODE_${node_id}_IP"
    alias="${!alias_var}"
    ip="${!ip_var}"
    log_info "$INFO_CONFIGURING_NODE" "Now" "$node_id" "$alias" "$ip"
    # each node gets a unique yaml
    compose_content=$(cat <<EOF
services:
  kafka:
    image: 'bitnamilegacy/kafka:latest'
    network_mode: host
    container_name: kafka_${node_id}
    volumes:
      - 'kafka_data:/bitnami/kafka'
    environment:
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_NODE_ID=${node_id}
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_CFG_LISTENERS=CONTROLLER://${ip}:9093,EXTERNAL://${ip}:9092
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT
      - KAFKA_CFG_INTER_BROKER_LISTENER_NAME=EXTERNAL
      - ALLOW_PLAINTEXT_LISTENER=yes
      - KAFKA_CLUSTER_ID=${KAFKA_CFG_CLUSTER_ID}
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=${KAFKA_QUORUM_VOTERS}
      - KAFKA_CFG_ADVERTISED_LISTENERS=EXTERNAL://${ip}:9092
      - KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=${KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR}
volumes:
  kafka_data:
    driver: local
EOF
)
    check_error
    if [ "$is_dry_run" = true ]; then
        log_info "DRY RUN: Would deploy the following docker-compose.yml to %s:" "$alias"
        log_info "DRY RUN: \n %s" "$compose_content"
    else
        ssh "$alias" "docker compose down --volumes &> /dev/null || true && echo '$compose_content' > docker-compose.yml"
        check_error
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

    validate_data

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
