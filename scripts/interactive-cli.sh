#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/lib/utilities.sh"
source "$SCRIPT_DIR/lib/cluster.sh"
source "$SCRIPT_DIR/lib/services.sh"
source "$SCRIPT_DIR/lib/version_manager.sh"
source "$SCRIPT_DIR/lib/custom_image_builder.sh"

# Main menu prompt
show_main_menu() {
  echo "╔══════════════════════════╗"
  echo "║ Kind Cluster Manager     ║"
  echo "╚══════════════════════════╝"
  echo
  echo "What would you like to do?"
  echo "1) Create Cluster"
  echo "2) Delete Cluster"
  echo "3) List Clusters"
  echo "4) Install Application"
  echo "5) Exit"
  echo
  read -p "Select option (1-5): " main_choice

  case $main_choice in
  1) handle_create_cluster ;;
  2) handle_delete_cluster ;;
  3) handle_list_clusters ;;
  4) handle_install_application ;;
  5)
    echo "Goodbye!"
    exit 0
    ;;
  *)
    echo "Invalid option. Please try again."
    show_main_menu
    ;;
  esac
}

# Handle cluster creation flow
handle_create_cluster() {
  echo
  echo "╔════════════════════════╗"
  echo "║ Select Cluster Profile ║"
  echo "╚════════════════════════╝"
  echo

  # Get cluster profiles from config
  local profiles=($(yq eval '.cluster_types | keys | .[]' config/config.yaml))
  local counter=1

  echo "Available cluster profiles:"
  for profile in "${profiles[@]}"; do
    local version=$(yq eval ".cluster_types.$profile.version" config/config.yaml)
    echo "$counter) $profile (v$version)"
    ((counter++))
  done
  echo "$counter) Back to main menu"
  echo

  read -p "Select cluster profile (1-$counter): " profile_choice

  # Validate choice
  if [[ $profile_choice -eq $counter ]]; then
    show_main_menu
    return
  elif [[ $profile_choice -ge 1 ]] && [[ $profile_choice -lt $counter ]]; then
    local selected_profile=${profiles[$((profile_choice - 1))]}
    show_applications_menu "$selected_profile"
  else
    echo "Invalid option. Please try again."
    handle_create_cluster
  fi
}

# Show applications menu after profile selection
show_applications_menu() {
  local profile=$1
  echo
  echo "╔══════════════════════════╗"
  echo "║ Select Applications      ║"
  echo "╚══════════════════════════╝"
  echo "Profile: $profile"
  echo

  # Get available services from config
  local services=($(yq eval '.services | keys[]' config/config.yaml))
  local counter=1

  echo "Available applications:"
  for service in "${services[@]}"; do
    local version=$(yq eval ".services.$service.version" config/config.yaml)
    echo "$counter) $service (v$version)"
    ((counter++))
  done
  echo "$counter) Create cluster without additional applications"
  echo "$((counter + 1))) Back to profile selection"
  echo

  read -p "Select applications (comma-separated numbers, or single number): " app_choice

  if [[ $app_choice -eq $counter ]]; then
    # Create cluster without apps
    create_cluster_with_apps "$profile" ""
  elif [[ $app_choice -eq $((counter + 1)) ]]; then
    # Go back to profile selection
    handle_create_cluster
  else
    # Parse selected applications
    local selected_apps=()
    IFS=',' read -ra choices <<<"$app_choice"
    for choice in "${choices[@]}"; do
      choice=$(echo "$choice" | xargs) # trim whitespace
      if [[ $choice -ge 1 ]] && [[ $choice -le ${#services[@]} ]]; then
        selected_apps+=(${services[$((choice - 1))]})
      fi
    done

    if [[ ${#selected_apps[@]} -gt 0 ]]; then
      local apps_string=$(
        IFS=','
        echo "${selected_apps[*]}"
      )
      create_cluster_with_apps "$profile" "$apps_string"
    else
      echo "No valid applications selected. Creating cluster without applications."
      create_cluster_with_apps "$profile" ""
    fi
  fi
}

# Create cluster with selected profile and applications
create_cluster_with_apps() {
  local profile=$1
  local apps=$2

  echo
  echo "Creating cluster with profile: $profile"
  if [[ -n "$apps" ]]; then
    echo "Applications to install: $apps"
  else
    echo "No additional applications will be installed."
  fi
  echo

  read -p "Enter cluster name (or press Enter for default): " cluster_name
  if [[ -z "$cluster_name" ]]; then
    cluster_name="kind-$profile-$(date +%s)"
  fi

  log "Creating cluster '$cluster_name'"

  # Call the create_cluster function
  if create_cluster "$profile" "$cluster_name"; then
    # Install selected applications
    if [[ -n "$apps" ]]; then
      log "Installing applications..."
      IFS=',' read -ra app_array <<<"$apps"
      for app in "${app_array[@]}"; do
        app=$(echo "$app" | xargs) # trim whitespace
        log "Installing $app..."
        if install_service "$app" "$cluster_name"; then
          log_success "$app installed successfully!"
        else
          log_error "Failed to install $app"
        fi
      done
    fi

    log_success "Cluster setup complete!"
    log "Cluster name: $cluster_name"
    log "Profile: $profile"
    [[ -n "$apps" ]] && log "Applications: $apps"
  else
    log_error "Failed to create cluster '$cluster_name'"
  fi

  echo
  read -p "Press Enter to return to main menu..."
  show_main_menu
}

# Handle cluster deletion
handle_delete_cluster() {
  echo
  echo "╔════════════════════════╗"
  echo "║ Delete Cluster         ║"
  echo "╚════════════════════════╝"
  echo

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo "No Kind clusters found."
    echo
    read -p "Press Enter to return to main menu..."
    show_main_menu
    return
  fi

  local counter=1
  echo "Available clusters to delete:"
  for cluster in "${clusters[@]}"; do
    echo "$counter) $cluster"
    ((counter++))
  done
  echo "$counter) Back to main menu"
  echo

  read -p "Select cluster to delete (1-$counter): " delete_choice

  if [[ $delete_choice -eq $counter ]]; then
    show_main_menu
    return
  elif [[ $delete_choice -ge 1 ]] && [[ $delete_choice -lt $counter ]]; then
    local selected_cluster=${clusters[$((delete_choice - 1))]}

    echo
    echo "⚠️  WARNING: This will permanently delete cluster '$selected_cluster'"
    read -p "Are you sure? (y/N): " confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
      log_warning "Deleting cluster '$selected_cluster'..."
      if delete_cluster "$selected_cluster"; then
        log_success "Cluster '$selected_cluster' deleted successfully!"
      else
        log_error "Failed to delete cluster '$selected_cluster'"
      fi
    else
      log "Deletion cancelled."
    fi
  else
    echo "Invalid option. Please try again."
    handle_delete_cluster
    return
  fi

  echo
  read -p "Press Enter to return to main menu..."
  show_main_menu
}

# Handle application installation to existing cluster
handle_install_application() {
  echo
  echo "╔══════════════════════════╗"
  echo "║ Install Application      ║"
  echo "╚══════════════════════════╝"
  echo

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo "No Kind clusters found. Please create a cluster first."
    echo
    read -p "Press Enter to return to main menu..."
    show_main_menu
    return
  fi

  # Show cluster selection
  local counter=1
  echo "Select target cluster:"
  for cluster in "${clusters[@]}"; do
    echo "$counter) $cluster"
    ((counter++))
  done
  echo "$counter) Back to main menu"
  echo

  read -p "Select cluster (1-$counter): " cluster_choice

  if [[ $cluster_choice -eq $counter ]]; then
    show_main_menu
    return
  elif [[ $cluster_choice -ge 1 ]] && [[ $cluster_choice -lt $counter ]]; then
    local selected_cluster=${clusters[$((cluster_choice - 1))]}
    show_application_install_menu "$selected_cluster"
  else
    echo "Invalid option. Please try again."
    handle_install_application
  fi
}

# Show applications menu for installation
show_application_install_menu() {
  local cluster=$1
  echo
  echo "╔══════════════════════════╗"
  echo "║ Select Application       ║"
  echo "╚══════════════════════════╝"
  echo "Target cluster: $cluster"
  echo

  # Get available services from config
  local services=($(yq eval '.services | keys[]' config/config.yaml))
  local counter=1

  echo "Available applications:"
  for service in "${services[@]}"; do
    local version=$(yq eval ".services.$service.version" config/config.yaml)

    # Check if application is already installed (optional check)
    local installed_status=""
    if kubectl get namespace "${service}" --context "kind-${cluster}" >/dev/null 2>&1; then
      installed_status=" (already installed)"
    fi

    echo "$counter) $service (v$version)$installed_status"
    ((counter++))
  done
  echo "$counter) Back to cluster selection"
  echo

  read -p "Select application to install (1-$counter): " app_choice

  if [[ $app_choice -eq $counter ]]; then
    handle_install_application
    return
  elif [[ $app_choice -ge 1 ]] && [[ $app_choice -lt $counter ]]; then
    local selected_app=${services[$((app_choice - 1))]}
    install_application_to_cluster "$selected_app" "$cluster"
  else
    echo "Invalid option. Please try again."
    show_application_install_menu "$cluster"
  fi
}

# Install application to specific cluster
install_application_to_cluster() {
  local app=$1
  local cluster=$2
  local version=$(yq eval ".services.$app.version" config/config.yaml)

  echo
  echo "╔══════════════════════════╗"
  echo "║ Installing Application   ║"
  echo "╚══════════════════════════╝"
  echo
  echo "Application: $app (v$version)"
  echo "Target cluster: $cluster"
  echo

  # Check if cluster is accessible
  if ! kubectl cluster-info --context "kind-$cluster" >/dev/null 2>&1; then
    log_error "Cannot access cluster '$cluster'. Please ensure it's running."
    echo
    read -p "Press Enter to return to main menu..."
    show_main_menu
    return
  fi

  # Check if application namespace already exists
  local namespace=$(yq eval ".services.$app.namespace" config/config.yaml 2>/dev/null || echo "$app")
  if kubectl get namespace "$namespace" --context "kind-$cluster" >/dev/null 2>&1; then
    echo "⚠️  Application '$app' appears to already be installed in cluster '$cluster'"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      echo "Installation cancelled."
      echo
      read -p "Press Enter to return to main menu..."
      show_main_menu
      return
    fi
  fi

  # Call the install_service function
  if install_service "$app" "$cluster"; then
    echo
    log_success "Application '$app' installed successfully to cluster '$cluster'!"
    echo
    echo "Installation Summary:"
    echo "- Application: $app (v$version)"
    echo "- Cluster: $cluster"
    echo "- Namespace: $namespace"

    # Show some basic status info
    echo
    echo "Checking installation status..."
    kubectl get pods -n "$namespace" --context "kind-$cluster" 2>/dev/null || echo "No pods found in namespace $namespace"
  else
    echo
    log_error "Failed to install application '$app' to cluster '$cluster'"
    echo "Please check the logs for more details."
  fi

  echo
  read -p "Press Enter to return to main menu..."
  show_main_menu
}
handle_list_clusters() {
  echo
  echo "╔════════════════════════╗"
  echo "║ Kind Clusters          ║"
  echo "╚════════════════════════╝"
  echo

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo "No Kind clusters found."
  else
    echo "Found ${#clusters[@]} cluster(s):"
    echo
    for i in "${!clusters[@]}"; do
      local cluster=${clusters[$i]}
      echo "$((i + 1)). $cluster"

      # Get cluster info if possible
      local status=$(kubectl cluster-info --context "kind-$cluster" 2>/dev/null | head -1 | grep -o "running" || echo "unknown")
      echo "   Status: $status"

      # Get node count
      local nodes=$(kubectl get nodes --context "kind-$cluster" --no-headers 2>/dev/null | wc -l || echo "0")
      echo "   Nodes: $nodes"
      echo
    done
  fi

  echo
  read -p "Press Enter to return to main menu..."
  show_main_menu
}

# Initialize and start
main() {
  # Check dependencies
  if ! check_dependencies; then
    log_error "Dependency check failed. Please install required tools."
    exit 1
  fi

  # Start main menu
  show_main_menu
}

# Run main function
main "$@"
