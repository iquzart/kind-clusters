#!/bin/bash
source ./utilities.sh
source ./custom_image_builder.sh

create_cluster() {
  local cluster_type=$1
  local config_file="config/cluster-profiles/${cluster_type}.yaml"
  local cluster_name="${cluster_type}-cluster"

  if ! yq eval ".cluster_types.$cluster_type" config/config.yaml >/dev/null 2>&1; then
    log_error "Invalid cluster type: $cluster_type"
    return 1
  fi

  check_port 80
  check_port 443

  build_custom_image_if_needed || return 1

  local node_image=$(get_cluster_image "$cluster_type")

  log "Creating ${cluster_name} using image ${node_image}..."

  kind create cluster \
    --name "$cluster_name" \
    --image "$node_image" \
    --config "$config_file" || {
    log_error "Cluster creation failed"
    return 1
  }

  log_success "Cluster ${cluster_name} created successfully"
  return 0
}

delete_cluster() {
  local cluster_name=$1

  if ! kind get clusters | grep -q "^${cluster_name}$"; then
    log_error "Cluster ${cluster_name} not found"
    return 1
  fi

  log "Deleting cluster ${cluster_name}..."
  kind delete cluster --name "$cluster_name" &&
    log_success "Cluster deleted" ||
    log_error "Cluster deletion failed"
}

list_clusters() {
  log "Available clusters:"
  kind get clusters || log_error "Failed to list clusters"
}

get_current_cluster() {
  kubectl config current-context | sed 's/kind-//'
}
