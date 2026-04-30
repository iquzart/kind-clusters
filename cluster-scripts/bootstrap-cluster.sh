#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

# ── Constants ────────────────────────────────────────────────────────────────
readonly APP_NAMES=(
  [1]="Nginx Ingress Controller"
  [2]="Kube Prometheus Stack"
  [3]="HashiCorp Vault"
  [4]="Tekton Pipelines"
  [5]="Trivy Operator"
)
readonly CLUSTER_CHOICES=("devops" "basic" "api-exposed" "cilium-cni" "envoy-gateway")

# ── Helpers ──────────────────────────────────────────────────────────────────
check_ports() {
  if netstat -ln | grep -qE ':80 |:443 '; then
    echo "Error: Port 80 or 443 is already in use." >&2
    exit 1
  fi
}

prompt_for_cluster() {
  echo "Select cluster configuration:"
  select choice in "${CLUSTER_CHOICES[@]}"; do
    [[ -z "${choice:-}" ]] && {
      echo "Invalid option. Try again."
      continue
    }
    CLUSTER_NAME="$choice"
    CLUSTER_CONFIG_FILE="cluster-configs/${CLUSTER_NAME}.yaml"
    export CLUSTER_NAME CLUSTER_CONFIG_FILE
    case "$choice" in
    cilium-cni) echo "Cilium CNI selected. Cilium will be installed." ;;
    envoy-gateway) echo "Envoy Gateway selected. Envoy Gateway will be installed." ;;
    esac
    break
  done
}

prompt_for_applications() {
  echo "Select applications to install (comma-separated, 0 = All):"
  local i=1
  for name in "${APP_NAMES[@]}"; do
    echo "  $((i++)). $name"
  done
  read -rp "Selections: " SELECTIONS
}

# ── Install functions ────────────────────────────────────────────────────────
install_app_by_index() {
  case "$1" in
  1) install_nginx_ingress ;;
  2) install_kube_prometheus_stack ;;
  3) install_hashicorp_vault ;;
  4) install_tekton ;;
  5) install_trivy_operator ;;
  *) echo "Invalid app selection: $1" >&2 ;;
  esac
}

install_all_apps() {
  for i in "${!APP_NAMES[@]}"; do
    install_app_by_index "$i"
  done
}

# ── Core ─────────────────────────────────────────────────────────────────────
create_cluster() {
  check_ports
  local image="${KIND_IMAGE}:${K8S_VERSION}"
  [[ "$ENABLE_CUSTOM_IMAGE" == "true" ]] && image="${image}-${KIND_CUSTOM_IMAGE_TAG}"
  envsubst <"$CLUSTER_CONFIG_FILE" | kind create cluster \
    --image "$image" \
    --name "$CLUSTER_NAME" \
    --config=-
}

install_apps() {
  # Source all helper scripts once
  for script in scripts/*.sh; do source "$script"; done

  # Cluster-level installs
  [[ "$CLUSTER_NAME" == "cilium-cni" ]] && {
    echo "Installing Cilium CNI..."
    install_cilium_cni
  }
  [[ "$CLUSTER_NAME" == "envoy-gateway" ]] && {
    echo "Installing Envoy Gateway..."
    install_envoy_gateway
  }

  # User-selected app installs
  if [[ -z "${SELECTIONS:-}" ]]; then
    echo "No apps selected."
    return
  fi

  IFS=',' read -ra APPS <<<"$SELECTIONS"
  for app in "${APPS[@]}"; do
    app="${app// /}" # trim whitespace
    [[ "$app" == "0" ]] && {
      install_all_apps
      return
    }
    install_app_by_index "$app"
  done
}

main() {
  ENABLE_CUSTOM_IMAGE="${1:-false}"
  prompt_for_cluster

  if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
    prompt_for_applications
  else
    echo "Creating cluster '$CLUSTER_NAME'..."
    prompt_for_applications
    create_cluster
  fi

  install_apps
}

main "$@"
