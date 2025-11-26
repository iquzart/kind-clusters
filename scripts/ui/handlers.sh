#!/bin/bash

# Cluster Handlers
# Handle cluster creation flow
handle_create_cluster() {
  menu_header "Select Cluster Profile"

  # Get cluster profiles from config
  local profiles=($(yq eval '.cluster_types | keys | .[]' config/config.yaml))
  local counter=1

  echo "Available cluster profiles:"
  for profile in "${profiles[@]}"; do
    local version=$(yq eval ".cluster_types.$profile.version" config/config.yaml)
    echo -e "${GREEN}$counter)${NC} $profile (v$version)"
    ((counter++))
  done
  echo -e "${BLUE}$counter)${NC} Back to main menu"
  echo

  read -p "Select cluster profile (1-$counter): " profile_choice

  # Validate choice
  if [[ $profile_choice -eq $counter ]]; then
    main_menu
    return
  elif [[ $profile_choice -ge 1 ]] && [[ $profile_choice -lt $counter ]]; then
    local selected_profile=${profiles[$((profile_choice - 1))]}
    # application_install_menu "$selected_profile" #TODO: Enable this once the cluster setup is ready
  else
    echo -e "${RED}Invalid option. Please try again.${NC}"
    handle_create_cluster
  fi
}

handle_list_clusters() {
  menu_header "Kind Clusters"

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No Kind clusters found.${NC}"
  else
    echo -e "Found ${GREEN}${#clusters[@]}${NC} cluster(s):"
    echo
    for i in "${!clusters[@]}"; do
      local cluster=${clusters[$i]}
      echo -e "${GREEN}$((i + 1)). $cluster${NC}"
      check_cluster_state "$cluster" # Call core function
      echo
    done
  fi
  echo
  read -p "Press Enter to return to main menu..."
  main_menu
}

# Handle cluster deletion
handle_delete_cluster() {
  menu_header "Delete Cluster"

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No Kind clusters found.${NC}"
    echo
    read -p "Press Enter to return to main menu..."
    main_menu
    return
  fi

  local counter=1
  echo "Available clusters to delete:"
  for cluster in "${clusters[@]}"; do
    echo -e "${RED}$counter)${NC} $cluster"
    ((counter++))
  done
  echo -e "${BLUE}$counter)${NC} Back to main menu"
  echo

  read -p "Select cluster to delete (1-$counter): " delete_choice

  if [[ $delete_choice -eq $counter ]]; then
    main_menu
    return
  elif [[ $delete_choice -ge 1 ]] && [[ $delete_choice -lt $counter ]]; then
    local selected_cluster=${clusters[$((delete_choice - 1))]}

    echo
    echo -e "${RED}⚠️  WARNING: This will permanently delete cluster '$selected_cluster'${NC}"
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
    echo -e "${RED}Invalid option. Please try again.${NC}"
    handle_delete_cluster
    return
  fi

  echo
  read -p "Press Enter to return to main menu..."
  main_menu
}

# Handle application installation to existing cluster
handle_install_application() {
  menu_header "Install Application"

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No Kind clusters found. Please create a cluster first.${NC}"
    echo
    read -p "Press Enter to return to main menu..."
    main_menu
    return
  fi

  # Show cluster selection
  local counter=1
  echo "Select target cluster:"
  for cluster in "${clusters[@]}"; do
    echo -e "${GREEN}$counter)${NC} $cluster"
    ((counter++))
  done
  echo -e "${BLUE}$counter)${NC} Back to main menu"
  echo

  read -p "Select cluster (1-$counter): " cluster_choice

  if [[ $cluster_choice -eq $counter ]]; then
    main_menu
    return
  elif [[ $cluster_choice -ge 1 ]] && [[ $cluster_choice -lt $counter ]]; then
    local selected_cluster=${clusters[$((cluster_choice - 1))]}
    show_application_install_menu "$selected_cluster"
  else
    echo -e "${RED}Invalid option. Please try again.${NC}"
    handle_install_application
  fi
}

# Install application to specific cluster
handle_install_application_to_cluster() {
  local app=$1
  local cluster=$2
  local version=$(yq eval ".services.$app.version" config/config.yaml)

  menu_header "Installing Application"
  echo
  echo -e "Application: ${YELLOW}$app${NC} (v$version)"
  echo -e "Target cluster: ${YELLOW}$cluster${NC}"
  echo

  # Check if cluster is accessible
  if ! kubectl cluster-info --context "kind-$cluster" >/dev/null 2>&1; then
    log_error "Cannot access cluster '$cluster'. Please ensure it's running."
    echo
    read -p "Press Enter to return to main menu..."
    main_menu
    return
  fi

  # Check if application namespace already exists
  local namespace=$(yq eval ".services.$app.namespace" config/config.yaml 2>/dev/null || echo "$app")
  if kubectl get namespace "$namespace" --context "kind-$cluster" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Application '$app' appears to already be installed in cluster '$cluster'${NC}"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Installation cancelled.${NC}"
      echo
      read -p "Press Enter to return to main menu..."
      main_menu
      return
    fi
  fi

  # Call the install_service function
  if install_service "$app" "$cluster"; then
    echo
    log_success "Application '$app' installed successfully to cluster '$cluster'!"
    echo
    echo "Installation Summary:"
    echo -e "- Application: ${YELLOW}$app${NC} (v$version)"
    echo -e "- Cluster: ${YELLOW}$cluster${NC}"
    echo -e "- Namespace: ${YELLOW}$namespace${NC}"

    # Show some basic status info
    echo
    log "Checking installation status..."
    kubectl get pods -n "$namespace" --context "kind-$cluster" 2>/dev/null || echo -e "${YELLOW}No pods found in namespace $namespace${NC}"
  else
    echo
    log_error "Failed to install application '$app' to cluster '$cluster'"
    echo -e "${RED}Please check the logs for more details.${NC}"
  fi

  echo
  read -p "Press Enter to return to main menu..."
  main_menu
}
