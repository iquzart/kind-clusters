#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/../config.sh"

check_ports() {
  if netstat -ln | grep -E ':80 |:443 '; then
    echo "Error: Port 80 or 443 is already in use."
    exit 1
  fi
}

prompt_for_cluster() {
  echo "Select cluster configuration:"
  select choice in "devops" "basic" "api-exposed" "cilium-cni"; do
    case "$choice" in
    devops | basic | api-exposed | cilium-cni)
      CLUSTER_NAME="${choice}"
      CLUSTER_CONFIG_FILE="cluster-configs/${CLUSTER_NAME}.yaml"
      export CLUSTER_NAME CLUSTER_CONFIG_FILE
      if [[ "$choice" == "cilium-cni" ]]; then
        echo "Cilium CNI selected. Cilium will be installed."
      fi
      break
      ;;
    *) echo "Invalid option. Try again." ;;
    esac
  done
}

prompt_for_applications() {
  echo "Select applications to install (comma-separated):"
  echo "  0. All"
  echo "  1. Nginx Ingress Controller"
  echo "  2. Kube Prometheus Stack"
  echo "  3. HashiCorp Vault"
  echo "  4. Tekton Pipelines"
  echo "  5. Trivy Operator"
  read -p "Selections: " SELECTIONS
}

create_cluster() {
  check_ports
  prompt_for_applications

  CONFIG=$(envsubst <"$CLUSTER_CONFIG_FILE")

  IMAGE="${KIND_IMAGE}:${K8S_VERSION}"
  [[ "$ENABLE_CUSTOM_IMAGE" == "true" ]] && IMAGE="${IMAGE}-${KIND_CUSTOM_IMAGE_TAG}"

  echo "$CONFIG" | kind create cluster --image "$IMAGE" --name "$CLUSTER_NAME" --config=-
}

install_apps() {
  [[ -z "${SELECTIONS:-}" ]] && APPS=("None") || IFS=',' read -ra APPS <<<"$SELECTIONS"

  for script in scripts/*.sh; do source "$script"; done

  # Install Cilium if the cluster is cilium-cni
  if [[ "$CLUSTER_NAME" == "cilium-cni" ]]; then
    echo "Installing Cilium CNI..."
    install_cilium_cni
  fi

  for app in "${APPS[@]}"; do
    case "$app" in
    0)
      install_nginx_ingress
      install_kube_prometheus_stack
      install_hashicorp_vault
      install_tekton
      install_trivy_operator
      ;;
    1) install_nginx_ingress ;;
    2) install_kube_prometheus_stack ;;
    3) install_hashicorp_vault ;;
    4) install_tekton ;;
    5) install_trivy_operator ;;
    "None") echo "No apps selected." ;;
    *) echo "Invalid app selection: $app" ;;
    esac
  done
}

main() {
  ENABLE_CUSTOM_IMAGE="${1:-false}"
  prompt_for_cluster

  if kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
    prompt_for_applications
  else
    echo "Creating cluster '$CLUSTER_NAME'..."
    create_cluster
  fi

  install_apps
}

main "$@"
