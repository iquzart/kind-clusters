#!/bin/bash

set -euo pipefail

readonly CLUSTER_NAME="devops-cluster"
readonly CLUSTER_CONFIG_FILE="cluster-configs/devops-cluster.yaml"
readonly KIND_IMAGE="kindest/node"
readonly KIND_CUSTOM_IMAGE_TAG="with-org-ca"
readonly K8S_VERSION=v1.26.3


# Check if port 80 or 443 is in use
check_ports() {
  if netstat -ln | grep ':80 ' || netstat -ln | grep ':443 '; then
    echo "Error: Port 80 or 443 is already in use."
    echo "Please ensure that any existing service using these ports does not conflict with the cluster's operation."
    exit 1
  fi
}

# Prompt user for which applications to install
prompt_for_applications() {
  echo "Which applications would you like to install? (separate with commas, or leave blank for none)"
  echo "0. All"
  echo "1. Nginx Ingress Controller"
  echo "2. Kube Prometheus Stack"
  echo "3. HashiCorp Vault"
  echo "4. Tekton Pipelines with UI"
  read -p "Enter your selection(s): " SELECTIONS
}

# Create a new Kind cluster
create_new_cluster() {
  check_ports
  prompt_for_applications

  # Use the custom image if 'custom-image' argument is provided and is set to 'true'
  if [ "${custom-image}" = "true" ]; then
    envsubst < $CLUSTER_CONFIG_FILE | kind create cluster --image $KIND_IMAGE:$K8S_VERSION-$KIND_CUSTOM_IMAGE_TAG --name $CLUSTER_NAME --config=-
  else
    envsubst < $CLUSTER_CONFIG_FILE | kind create cluster --image $KIND_IMAGE:$K8S_VERSION --name $CLUSTER_NAME --config=-
  fi

}

# Entry point
main() {

  # Source all scripts in the scripts/ directory
  for APP_INSTALL_SCRIPT in ./scripts/*.sh; do
    source "$APP_INSTALL_SCRIPT"
  done

  # Check if cluster exists if not create it
  if kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "Cluster $CLUSTER_NAME already exists. Skipping cluster creation."
    prompt_for_applications
  else
    echo "Creating $CLUSTER_NAME..."
    create_new_cluster
  fi

  if [[ -z "$SELECTIONS" ]]; then
    APPS=("None")
  else
    IFS=',' read -ra APPS <<< "$SELECTIONS"
  fi


  # Install selected applications
  for APP in "${APPS[@]}"; do
    case "$APP" in
      0)
        install_nginx_ingress
        install_kube_prometheus_stack
        install_hashicorp_vault
        install_tekton
        ;;
      1)
        install_nginx_ingress
        ;;
      2)
        install_kube_prometheus_stack
        ;;
      3)
        install_hashicorp_vault
        ;;
      4)
        install_tekton
        ;;
      "None")
        echo "No applications selected"
        ;;
      *)
        echo "Invalid selection: $APP"
        ;;
    esac
  done
}

main
