#!/bin/bash

# Simplified menu display function
display_menu_header() {
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

# Main menu prompt
main_menu() {
  display_menu_header "Kind Cluster Manager"

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
