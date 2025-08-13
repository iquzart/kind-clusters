#!/bin/bash

create_cluster() {
  local cluster_type=$1
  local cluster_name="$2"
  local config_file="config/cluster-profiles/${cluster_type}.yaml"

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
    --config "$config_file" >/dev/null 2>&1 || {
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

  kind delete cluster --name "$cluster_name" >/dev/null 2>&1
}

check_cluster_state() {
  local cluster=$1
  # Get cluster status
  local status=$(kubectl cluster-info --context "kind-$cluster" 2>/dev/null | head -1 | grep -o "running" || echo "unknown")
  [[ "$status" == "running" ]] && status="${GREEN}$status${NC}" || status="${RED}$status${NC}"
  echo -e "   Status: $status"

  # Get node count
  local nodes=$(kubectl get nodes --context "kind-$cluster" --no-headers 2>/dev/null | wc -l || echo "0")
  echo "   Nodes: $nodes"
}

get_current_cluster() {
  kubectl config current-context | sed 's/kind-//'
}
