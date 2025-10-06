#!/usr/bin/env bash

# --- General ---
MSG_ERROR_PREFIX="♘ Error:"
MSG_SUCCESS_PREFIX="♖"
MSG_INFO_PREFIX="♗"
MSG_CONFIGURING_PREFIX="♕"
MSG_DEPLOYING_PREFIX="♔"

# --- Generic Info ---
INFO_DRY_RUN_STARTED="[DRY RUN] Dry run started. No changes will be made."
INFO_DRY_RUN_COMPLETE="[DRY RUN] Dry run complete. No changes were made."

# --- generate_data.sh Messages ---
INFO_READING_NODE_ALIASES="Reading node aliases from '%s'..."
INFO_FOUND_NODES="Found %s nodes to process."
INFO_GENERATING_NODE_DATA="Generating node data and voter string..."
INFO_DISCOVERING_IP_FOR_ALIAS="Discovering IP for '%s'..."
SUCCESS_DATA_GENERATED="Data file has been successfully generated."

# --- deploy_config.sh Messages ---
INFO_VALIDATING_DATA="Validating data from '%s'..."
SUCCESS_VALIDATION="Data validated successfully."
INFO_DISTRIBUTING_FILES="Distributing static files"
INFO_COPYING_FILE="Copying '%s' to '%s'"
INFO_STARTING_CONFIGURATION="Starting paralell configuration of %d nodes..."
INFO_CONFIGURING_NODE="'%s' Configuring Node '%s' '%s' ('%s')"
INFO_CONFIGURING_NODE_COMPLETE="Completed configuration of '%s'."
SUCCESS_DEPLOYMENT_COMPLETE="All nodes have been configured."

# --- Error Messages ---
ERROR_NO_IP_FOR_INTERFACE="Could not find IP for interface '%s'."
ERROR_IP_DISCOVERY_FAILED="IP discovery failed for alias '%s'."
ERROR_DATA_FILE_NOT_FOUND="Data file not found. Please run 'generate_data.sh' first."
ERROR_NODE_COUNT_INVALID="'NODE_COUNT' is missing, zero, or invalid. Please re-run 'generate_data.sh'."
ERROR_DATA_INCOMPLETE="Data for Node '%s' is incomplete (missing '%s')."
ERROR_DATA_INCONSISTENT="Data file is inconsistent. Expected %d nodes, but found %d."


# --- TUI Messages ---
TUI_SETUP_WIZARD_TITLE="Setup Wizard '%s'"
TUI_INTERFACE_PROMPT="Pick the network interface to use."
TUI_TITLE="Kafka Pi Cluster Manager"
TUI_MENU_PROMPT="Please enter your choice: "
TUI_GENERATE_OPTION="Generate Cluster Data (Compile)"
TUI_DEPLOY_OPTION="Deploy Configuration to Nodes"
TUI_START_OPTION="Start Kafka Cluster"
TUI_STOP_OPTION="Stop Kafka Cluster"
TUI_QUIT_OPTION="Quit"
TUI_COMPILING_DATA="Compiling cluster data..."
TUI_DATA_COMPILED="Data compilation complete."
TUI_DEPLOYING_CONFIGURATION="Deploying configuration..."
TUI_CONFIGURATION_DEPLOYED="Configuration deployment complete."
TUI_STARTING_CLUSTER="Starting Kafka cluster..."
TUI_CLUSTER_STARTED="Kafka cluster started."
TUI_STOPPING_CLUSTER="Stopping Kafka cluster..."
TUI_CLUSTER_STOPPED="Kafka cluster stopped."
TUI_QUIT="Exiting."
TUI_INVALID_OPTION="Invalid option: %s"
TUI_PRESS_ENTER_TO_RETURN="Press Enter to return to the menu..."
