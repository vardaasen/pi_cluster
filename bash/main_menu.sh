#!/usr/bin/env bash
# shellcheck source=./messages.sh
source ./messages.sh
# shellcheck source=./logging.sh
. ./logging.sh
log_init

PROJECT_CONF="project.conf"
NODES_CONF="../nodes.conf"

run_first_time_setup() {
    clear
    local interfaces
    local menu_items
    local selected_choice
    local selected_interface
    local iface
    local ip


    log_info "$TUI_SETUP_WIZARD_TITLE" "Welcom! Let's configure your project"

    log_info "$TUI_INTERFACE_PROMPT"
    interfaces=()
    for i in {0..9}; do
        iface="en$i"
        ip=$(ipconfig getifaddr "$iface" 2>/dev/null) || true

        # If an IP was found AND it's not a self-assigned address...
        if [[ -n "$ip" && "$ip" != 169.254.* ]]; then
            # ...add it to our menu options.
            interfaces+=("$iface ($ip)")
        fi
    done
    PS3="Enter the number for your interface: "
    select choice in "${interfaces[@]}"; do
        if [[ -n "$choice" ]]; then
            selected_choice="$choice"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
    # Extract just the device name (e.g., "en3") from the user's choice
    selected_interface=$(echo "$selected_choice" | awk '{print $1}')
    # Save the selected interface to the project config file
    echo "NETWORK_INTERFACE=\"$selected_interface\"" > "$PROJECT_CONF"
    log_info "Saved network interface '$selected_interface' to '$PROJECT_CONF'."
    echo ""
}
# Check if config exists, if not, run setup
if ! [ -r "$PROJECT_CONF" ] || ! (. "$PROJECT_CONF" && [ -n "$NETWORK_INTERFACE" ]); then
    run_first_time_setup
fi
options=(
    "$TUI_GENERATE_OPTION"
    "$TUI_DEPLOY_OPTION"
    "Start Kafka Cluster"
    "Stop Kafka Cluster"
    "Quit"
)

print_header() {
    clear
    log_info "$TUI_TITLE"
}

# --- Main TUI Logic ---
while true; do
    print_header
    PS3="Please enter your choice: "
    
    select opt in "${options[@]}"; do
        case $opt in
            "$TUI_GENERATE_OPTION")
                print_header
                log_info "$TUI_COMPILING_DATA"
                ./generate_data.sh
                log_info "$TUI_DATA_COMPILED"
                break
                ;;
            "$TUI_DEPLOY_OPTION")
                print_header
                log_info "$TUI_DEPLOYING_CONFIGURATION"
                ./deploy_config.sh
                log_info "$TUI_CONFIGURATION_DEPLOYED"
		break
                ;;
            "Start Kafka Cluster")
                print_header
                log_info "$TUI_STARTING_CLUSTER"
                ./start_cluster.sh
                log_info "$TUI_CLUSTER_STARTED"
                break
                ;;
            "Stop Kafka Cluster")
                print_header
                log_info "$TUI_STOPPING_CLUSTER"
                echo "-> Stop script not yet implemented."
                break
                ;;
            "Quit")
                log_info "$TUI_QUIT"
                exit 0
                ;;
            *) 
                log_info "$TUI_INVALID_OPTION" "$REPLY"
                break
                ;;
        esac
    done
    
    read -rp "$TUI_PRESS_ENTER_TO_RETURN"
done
