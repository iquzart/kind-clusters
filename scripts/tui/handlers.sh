#!/bin/bash

# Cluster Handlers
# Handle cluster creation flow
handle_create_cluster() {
  display_menu_header "Select Cluster Profile"

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
    show_main_menu
    return
  elif [[ $profile_choice -ge 1 ]] && [[ $profile_choice -lt $counter ]]; then
    local selected_profile=${profiles[$((profile_choice - 1))]}
    show_applications_menu "$selected_profile"
  else
    echo -e "${RED}Invalid option. Please try again.${NC}"
    handle_create_cluster
  fi
}

handle_list_clusters() {
  display_menu_header "Kind Clusters"

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
  display_menu_header "Delete Cluster"

  # Get existing clusters
  local clusters=($(kind get clusters 2>/dev/null))

  if [[ ${#clusters[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No Kind clusters found.${NC}"
    echo
    read -p "Press Enter to return to main menu..."
    show_main_menu
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
