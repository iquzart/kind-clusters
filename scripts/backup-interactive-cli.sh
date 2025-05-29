#!/bin/bash
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/lib/utilities.sh"
source "$SCRIPT_DIR/lib/cluster.sh"
source "$SCRIPT_DIR/lib/services.sh"
source "$SCRIPT_DIR/lib/version_manager.sh"
source "$SCRIPT_DIR/lib/custom_image_builder.sh"

# Main Orchestration Functions

manage_clusters() {
  while true; do
    clear
    echo "╔══════════════════════╗"
    echo "║ Cluster Management   ║"
    echo "╚══════════════════════╝"
    echo
    echo "1) Create Cluster"
    echo "2) Delete Cluster"
    echo "3) List Clusters"
    echo "4) Back to Main"
    echo
    read -p "Select (1-4): " choice

    case $choice in
    1) create_cluster_flow ;;
    2) delete_cluster_flow ;;
    3) list_clusters_flow ;;
    4) break ;;
    *) invalid_option ;;
    esac
    sleep 1
  done
}

create_cluster_flow() {
  echo "Available cluster types:"
  local types=($(yq eval '.cluster_types | keys | .[]' config/config.yaml))
  select type in "${types[@]}" "Back"; do
    [[ "$type" == "Back" ]] && return
    create_cluster "$type" && break || sleep 2
  done
}

delete_cluster_flow() {
  echo "Available clusters:"
  local clusters=($(kind get clusters))
  select cluster in "${clusters[@]}" "Back"; do
    [[ "$cluster" == "Back" ]] && return
    delete_cluster "$cluster" && break || sleep 2
  done
}

list_clusters_flow() {
  list_clusters
  read -p "Press enter to continue..."
}

# Similar orchestration flows for services and versions
manage_services() {
  while true; do
    clear
    echo "╔══════════════════════╗"
    echo "║ Service Management   ║"
    echo "╚══════════════════════╝"
    echo
    echo "1) Install Service"
    echo "2) Uninstall Service"
    echo "3) List Services"
    echo "4) Back to Main"
    echo
    read -p "Select (1-4): " choice

    case $choice in
    1) install_service_flow ;;
    2) uninstall_service_flow ;;
    3) list_services_flow ;;
    4) break ;;
    *) invalid_option ;;
    esac
    sleep 1
  done
}

install_service_flow() {
  local cluster=$(get_current_cluster)
  echo "Available services:"
  local services=($(yq eval '.services | keys[]' config/config.yaml))
  select service in "${services[@]}" "Back"; do
    [[ "$service" == "Back" ]] && return
    install_service "$service" "$cluster" && break || sleep 2
  done
}

# Main Menu
main_menu() {
  while true; do
    clear
    echo "╔══════════════════════════╗"
    echo "║   Kind Cluster Manager   ║"
    echo "╚══════════════════════════╝"
    echo
    echo "1) Manage Clusters"
    echo "2) Manage Services"
    echo "3) Manage Versions"
    echo "4) Exit"
    echo
    read -p "Select (1-4): " choice

    case $choice in
    1) manage_clusters ;;
    2) manage_services ;;
    3) manage_versions ;;
    4) exit 0 ;;
    *) invalid_option ;;
    esac
  done
}

# Start the CLI
check_dependencies || exit 1
main_menu
