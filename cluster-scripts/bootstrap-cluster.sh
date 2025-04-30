set -euo pipefail

source "$(dirname "$0")/../config.sh"

check_ports() {
  if netstat -ln | grep -E ':80 |:443 '; then
    log_error "Port 80 or 443 is already in use."
    exit 1
  fi
}

prompt_for_cluster() {
  echo -e "${MAGENTA}==> Select a cluster configuration:${RESET}"
  select choice in "devops" "basic" "api-exposed" "cilium-cni"; do
    case "$choice" in
    devops | basic | api-exposed | cilium-cni)
      CLUSTER_NAME="${choice}"
      CLUSTER_CONFIG_FILE="cluster-configs/${CLUSTER_NAME}.yaml"
      export CLUSTER_NAME CLUSTER_CONFIG_FILE
      if [[ "$choice" == "cilium-cni" ]]; then
        log_success "Selected: ${MAGENTA}${CLUSTER_NAME}${RESET} — Cilium will be installed."
      else
        log_success "Selected: ${MAGENTA}${CLUSTER_NAME}${RESET}"
      fi
      break
      ;;
    *)
      log_error "Invalid option. Please try again."
      ;;
    esac
  done
}

prompt_for_applications() {
  echo -e "${MAGENTA}==> Select applications to install (comma-separated):${RESET}"
  echo -e "${BLUE}  [0]${RESET} All"
  echo -e "${BLUE}  [1]${RESET} Nginx Ingress Controller"
  echo -e "${BLUE}  [2]${RESET} Kube Prometheus Stack"
  echo -e "${BLUE}  [3]${RESET} HashiCorp Vault"
  echo -e "${BLUE}  [4]${RESET} Tekton Pipelines"
  echo -e "${BLUE}  [5]${RESET} Trivy Operator"
  echo -ne "${MAGENTA}==> Your selection:${RESET} "
  read SELECTIONS
}

create_cluster() {
  check_ports
  prompt_for_applications

  CONFIG=$(envsubst <"$CLUSTER_CONFIG_FILE")

  IMAGE="${KIND_IMAGE}:${K8S_VERSION}"
  [[ "$ENABLE_CUSTOM_IMAGE" == "true" ]] && IMAGE="${IMAGE}-${KIND_CUSTOM_IMAGE_TAG}"

  log_info "Creating Kind cluster with image: ${IMAGE}"
  echo "$CONFIG" | kind create cluster --image "$IMAGE" --name "$CLUSTER_NAME" --config=-
}

install_apps() {
  [[ -z "${SELECTIONS:-}" ]] && APPS=("None") || IFS=',' read -ra APPS <<<"$SELECTIONS"

  for script in scripts/*.sh; do source "$script"; done

  # Install Cilium if the cluster is cilium-cni
  if [[ "$CLUSTER_NAME" == "cilium-cni" ]]; then
    log_info "Installing Cilium CNI..."
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
    "None") log_info "No apps selected." ;;
    *) log_warn "Invalid app selection: $app" ;;
    esac
  done
}

main() {
  ENABLE_CUSTOM_IMAGE="${1:-false}"
  prompt_for_cluster

  if kind get clusters | grep -q "$CLUSTER_NAME"; then
    log_info "Cluster '${CLUSTER_NAME}' already exists. Skipping creation."
    prompt_for_applications
  else
    log_info "Creating cluster '${CLUSTER_NAME}'..."
    create_cluster
  fi

  install_apps
}

main "$@"
