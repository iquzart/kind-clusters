#!/bin/bash
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/../../scripts/lib/services.sh"
source "$SCRIPT_DIR/../../scripts/lib/utilities.sh"

CLUSTER=${1:-$(kubectl config current-context | sed 's/kind-//')}

install() {
  log_header "Starting Vault Installation on $CLUSTER"

  # Pre-flight checks
  check_dependencies || return 1
  validate_cluster_name "$CLUSTER" || return 1

  # Install Vault via Helm
  if ! install_service "vault" "$CLUSTER"; then
    return 1
  fi

  # Initialize Vault
  initialize_vault

  log_success "Vault setup complete"
  log_warning "Root token: $VAULT_TOKEN"
  log_warning "Unseal key: $VAULT_UNSEAL_KEY"
}

initialize_vault() {
  log "Initializing Vault..."

  # Wait for Vault pod to be ready
  kubectl wait --namespace vault \
    --for=condition=Ready pod/vault-0 \
    --timeout=300s \
    --context "kind-$CLUSTER"

  # Initialize and capture output
  init_output=$(kubectl exec vault-0 --namespace vault --context "kind-$CLUSTER" -- \
    vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json)

  # Parse and export keys
  export VAULT_TOKEN=$(echo "$init_output" | jq -r '.root_token')
  export VAULT_UNSEAL_KEY=$(echo "$init_output" | jq -r '.unseal_keys_b64[0]')
  export VAULT_ADDR='http://vault.vault.svc:8200'

  # Unseal Vault
  kubectl exec vault-0 --namespace vault --context "kind-$CLUSTER" -- \
    vault operator unseal "$VAULT_UNSEAL_KEY"
}

uninstall() {
  log "Uninstalling Vault from $CLUSTER..."
  helm uninstall vault --namespace vault --kube-context "kind-$CLUSTER"
}

"${@:-install}"
