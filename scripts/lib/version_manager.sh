#!/bin/bash
source ./utilities.sh

CONFIG_FILE="../config/config.yaml"

validate_version() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    log_error "Invalid version format (use X.Y.Z)"
    return 1
  }
}

get_service_version() {
  local service=$1
  yq eval ".services.$service.version" "$CONFIG_FILE" || {
    log_error "Failed to get version"
    return 1
  }
}

update_service_version() {
  local service=$1
  local version=$2

  validate_version "$version" || return 1

  yq eval ".services.$service.version = \"$version\"" -i "$CONFIG_FILE" &&
    log_success "Version updated to $version" ||
    log_error "Version update failed"
}

list_service_versions() {
  log "Current service versions:"
  yq eval '.services | with_entries(.value |= .version)' "$CONFIG_FILE" ||
    log_error "Failed to list versions"
}
