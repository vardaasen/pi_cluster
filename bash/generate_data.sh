#!/usr/bin/env bash

# shellcheck source=./regexp_lib.sh
. ./regexp_lib.sh
# shellcheck source=./messages.sh
. ./messages.sh
# shellcheck source=./logging.sh
. ./logging.sh
log_init
CONFIG_FILE="../nodes.conf"
DATA_FILE="cluster.data"

confirm_and_clean() {
    if [ ! -f "$DATA_FILE" ]; then
        return # No old data found, so we can proceed safely
    fi

    # Warn the user and ask for confirmation
    read -p "🚨 WARNING: Existing cluster data found. Re-generating will destroy all Kafka data. Are you sure? (y/N) " -n 1 -r
    echo # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted by user."
        exit 1
    fi

    # If the user confirmed, clean up the old volumes
    echo "--- 🔥 Destroying old cluster data on all nodes... ---"
    source "$DATA_FILE"
    for (( i=1; i<=NODE_COUNT; i++ )); do
        local alias_var="NODE_${i}_ALIAS"; local alias="${!alias_var}"
        echo "  -> Cleaning up $alias"
        ssh "$alias" 'docker compose down --volumes'
	check_error
    done
}

main() {
    local NODE_ID
    local quorum_voters
    local IP
    local CLUSTER_ID
    confirm_and_clean

    log_info "$INFO_READING_NODE_ALIASES" "$CONFIG_FILE"
    mapfile -t PI_ALIASES < <( \
        sed -e "$SED_PATTERN_INLINE_COMMENT" \
            -e "$SED_PATTERN_DELETE_EMPTY_LINES" \
            "$CONFIG_FILE" \
    )
    check_error
    log_info "$INFO_FOUND_NODES" "${#PI_ALIASES[@]}"

    # Clear the data file
    : > "$DATA_FILE"
    check_error
    # Write total nodes to data file
    echo "NODE_COUNT=${#PI_ALIASES[@]}" >> "$DATA_FILE"
    check_error
    # generate a unique kafka cluster id
    CLUSTER_ID=$(docker run --rm bitnamilegacy/kafka:latest kafka-storage.sh random-uuid 2>&1 | tail -n 1)
    check_error

    log_info "$INFO_GENERATING_NODE_DATA"
    NODE_ID=0
    quorum_voters=""
    for alias in "${PI_ALIASES[@]}"; do
      NODE_ID=$((NODE_ID + 1))
      log_info "$INFO_DISCOVERING_IP_FOR_ALIAS" "$alias"
      IP=$(ssh -G "$alias" | awk '/^hostname / { print $2 }')
      check_error

      if [ -z "$IP" ]; then
        log_error "$ERROR_IP_DISCOVERY_FAILED" "$alias"
        exit 1
      fi
      # Writing to data file
      echo "NODE_${NODE_ID}_ALIAS=$alias" >> "$DATA_FILE"
      check_error
      echo "NODE_${NODE_ID}_IP=$IP" >> "$DATA_FILE"
      check_error

      # Build quorum voters string
      if [ -n "$quorum_voters" ]; then
        quorum_voters+="," # comma before all entries except the first
      fi
      quorum_voters+="${NODE_ID}@${IP}:9093"
    done
    # --- Write Shared Kafka Configuration Data ---
    # Using cat and a heredoc is cleaner for multi-line variables.
    cat >> "$DATA_FILE" <<EOF
# Shared Kafka Configuration
KAFKA_CFG_CLUSTER_ID="$CLUSTER_ID"
KAFKA_QUORUM_VOTERS="$quorum_voters"
# KRaft mode is enabled by setting KAFKA_CFG_PROCESS_ROLES
KAFKA_CFG_PROCESS_ROLES="broker,controller"
KAFKA_CFG_CONTROLLER_LISTENER_NAMES="CONTROLLER"
KAFKA_CFG_LISTENERS="INTERNAL://:9091,CONTROLLER://:9093,EXTERNAL://:9092"
KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP="INTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT"
KAFKA_CFG_INTER_BROKER_LISTENER_NAME="EXTERNAL"
# Metadata distibuted between nodes in the cluster, REPLICATION_FACTOR, 3 is a magic number
KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=3
KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=3
KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR=2
ALLOW_PLAINTEXT_LISTENER="yes"
EOF
    check_error
    log_info "${SUCCESS_DATA_GENERATED}"
}

main
