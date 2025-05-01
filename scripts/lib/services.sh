#!/bin/bash
source ./utilities.sh

service_exists() {
  local cluster=$1
  local service=$2
  helm list -n "$service" --kube-context "kind-$cluster" | grep -q "$service"
}

get_service_config() {
  local service=$1
  local key=$2
  yq eval ".services.$service.$key" config/config.yaml
}

install_service() {
  local service=$1
  local cluster=$2

  log "Installing ${service} on ${cluster}..."

  local version=$(get_service_config "$service" "version")
  local repo_url=$(get_service_config "$service" "repo_url")
  local repo_name=$(get_service_config "$service" "repo_name")
  local namespace=$(get_service_config "$service" "namespace")

  # Add Helm repo if not exists
  if ! helm repo list | grep -q "$repo_name"; then
    helm repo add "$repo_name" "$repo_url" || return 1
    helm repo update
  fi

  # Install service
  helm upgrade --install "$service" "$repo_name/$service" \
    --version "$version" \
    --namespace "$namespace" \
    --create-namespace \
    --kube-context "kind-$cluster" \
    --values "services/$service/values/values-kind.yaml"

  if [ $? -eq 0 ]; then
    log_success "${service} installed successfully"
    return 0
  else
    log_error "Failed to install ${service}"
    return 1
  fi
}

uninstall_service() {
  local service=$1
  local cluster=$2

  if ! service_exists "$cluster" "$service"; then
    log_error "Service $service not found on $cluster"
    return 1
  fi

  helm uninstall "$service" --namespace "$namespace" &&
    log_success "Service uninstalled" ||
    log_error "Uninstall failed"
}

list_services() {
  local cluster=$1
  log "Services on $cluster:"
  helm list --all-namespaces --kube-context "kind-$cluster" ||
    log_error "Failed to list services"
}

helm_release_exists() {
  local cluster=$1
  local release=$2
  helm list -n "$release" --kube-context "kind-$cluster" | grep -q "$release"
}
