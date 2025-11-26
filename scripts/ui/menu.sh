#!/bin/bash

# menu display function
menu_header() {
  local title="$1"
  local padding=2 # Spaces on each side of the title
  local plain_title=$(echo -e "$title" | sed 's/\x1B\[[0-9;]*[mK]//g')
  local title_length=${#plain_title}
  local box_width=$((title_length + padding * 2))

  # Create borders dynamically
  local top_border="╔$(printf '═%.0s' $(seq 1 $box_width))╗"
  local bottom_border="╚$(printf '═%.0s' $(seq 1 $box_width))╝"
  local middle_line="║${NC}${YELLOW}$(printf '%*s' $(((box_width - title_length) / 2)) "")${title}$(printf '%*s' $(((box_width - title_length + 1) / 2)) "")${NC}${BLUE}║"

  echo
  echo -e "${BLUE}${top_border}${NC}"
  echo -e "${BLUE}${middle_line}${NC}"
  echo -e "${BLUE}${bottom_border}${NC}"
  echo
}

# # Show applications menu for installation
# application_install_menu() {
#   local cluster=$1
#   menu_header "Select Application"
#   echo -e "Target cluster: ${YELLOW}$cluster${NC}"
#   echo
#
#   # Get available services from config
#   local services=($(yq eval '.services | keys[]' config/config.yaml))
#   local counter=1
#
#   echo "Available applications:"
#   for service in "${services[@]}"; do
#     local version=$(yq eval ".services.$service.version" config/config.yaml)
#
#     # Check if application is already installed (optional check)
#     local installed_status=""
#     if kubectl get namespace "${service}" --context "kind-${cluster}" >/dev/null 2>&1; then
#       installed_status=" ${GREEN}(already installed)${NC}"
#     fi
#
#     echo -e "${GREEN}$counter)${NC} $service (v$version)$installed_status"
#     ((counter++))
#   done
#   echo -e "${BLUE}$counter)${NC} Back to cluster selection"
#   echo
#
#   read -p "Select application to install (1-$counter): " app_choice
#
#   if [[ $app_choice -eq $counter ]]; then
#     handle_install_application
#     return
#   elif [[ $app_choice -ge 1 ]] && [[ $app_choice -lt $counter ]]; then
#     local selected_app=${services[$((app_choice - 1))]}
#     handle_install_application_to_cluster "$selected_app" "$cluster"
#   else
#     echo -e "${RED}Invalid option. Please try again.${NC}"
#     application_install_menu "$cluster"
#   fi
# }

# Show applications menu after profile selection
show_applications_menu() {
  local profile=$1
  display_menu_header "Select Applications"
  echo -e "Profile: ${YELLOW}$profile${NC}"
  echo

  # Get available services from config
  local services=($(yq eval '.services | keys[]' config/config.yaml))
  local counter=1

  echo "Available applications:"
  for service in "${services[@]}"; do
    local version=$(yq eval ".services.$service.version" config/config.yaml)
    echo -e "${GREEN}$counter)${NC} $service (v$version)"
    ((counter++))
  done
  echo -e "${GREEN}$counter)${NC} Create cluster without additional applications"
  echo -e "${BLUE}$((counter + 1)))${NC} Back to profile selection"
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
      echo -e "${YELLOW}No valid applications selected. Creating cluster without applications.${NC}"
      create_cluster_with_apps "$profile" ""
    fi
  fi
}

# Main menu prompt
main_menu() {
  menu_header "Kind Cluster Manager"

  echo "What would you like to do?"
  echo -e "${GREEN}1)${NC} Create Cluster"
  echo -e "${GREEN}2)${NC} Delete Cluster"
  echo -e "${GREEN}3)${NC} List Clusters"
  echo -e "${GREEN}4)${NC} Install Application"
  echo -e "${RED}q)${NC} Exit"
  echo

  read -p "Select option (1-4): " main_choice

  case $main_choice in
  1) handle_create_cluster ;;
  2) handle_delete_cluster ;;
  3) handle_list_clusters ;;
  4) handle_install_application ;;
  q)
    echo -e "${GREEN}Goodbye!${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid option. Please try again.${NC}"
    main_menu
    ;;
  esac
}
