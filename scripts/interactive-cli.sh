#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/lib/utilities.sh"
source "$SCRIPT_DIR/lib/cluster.sh"
source "$SCRIPT_DIR/lib/services.sh"
source "$SCRIPT_DIR/lib/version_manager.sh"
source "$SCRIPT_DIR/lib/custom_image_builder.sh"
source "$SCRIPT_DIR/tui/menus.sh"
source "$SCRIPT_DIR/tui/handlers.sh"

# Parse command line arguments
parse_arguments() {
  case "$1" in
  create)
    handle_create_cluster
    ;;
  delete)
    handle_delete_cluster
    ;;
  list)
    handle_list_clusters
    ;;
  install-apps)
    handle_install_application
    ;;
  help | --help | -h)
    show_usage
    ;;
  "")
    main_menu
    ;;
  *)
    echo -e "${RED}Error: Unknown command '$1'${NC}"
    echo
    show_usage
    exit 1
    ;;
  esac
}

# Show Usage
show_usage() {
  echo "Kind Cluster Manager"
  echo
  echo "Usage: $0 [COMMAND]"
  echo
  echo "Commands:"
  echo -e "  ${GREEN}create${NC}       Create a new Kind cluster"
  echo -e "  ${GREEN}delete${NC}       Delete an existing Kind cluster"
  echo -e "  ${GREEN}list${NC}         List all Kind clusters"
  echo -e "  ${GREEN}install-apps${NC} Install applications to cluster"
  echo -e "  ${GREEN}help${NC}         Show this help message"
  echo
  echo "If no command is provided, interactive menu will be shown."
}

# Initialize and start
main() {
  # Check dependencies
  if ! check_dependencies; then
    log_error "Dependency check failed. Please install required tools."
    exit 1
  fi

  parse_arguments "$@"
  # Start main menu
  # main_menu "$1"
}

# Run main function
main "$@"
