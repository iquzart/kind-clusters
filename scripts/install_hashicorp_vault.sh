function install_hashicorp_vault() {
  log_info "Installing HashiCorp Vault with Helm..."

  if ! helm repo list | grep -q "hashicorp"; then
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update
  else
    log_info "HashiCorp repository already exists. Skipping add."
  fi

  helm upgrade -i kind-vault -n vault --create-namespace \
    --atomic -f apps/hashicorp-vault/deploy/values-kind-vault.yaml apps/hashicorp-vault/deploy/vault-helm-0.22.1

  if [ $? -eq 0 ]; then
    log_success "Vault installation was successful!"
  else
    log_error "Vaultinstallation failed. Please check the logs."
    return 1
  fi

  log_info "Cleaning up previous configurations..."
  rm -rf apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster
  mkdir -p apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster

  log_info "Retrieving Kubernetes certificate and token..."
  kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode >apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster/ca.pem
  if [ $? -eq 0 ]; then
    log_success "Kubernetes certificate retrieved successfully!"
  else
    log_error "Failed to retrieve Kubernetes certificate. Please check the logs."
    return 1
  fi

  kubectl get secret kind-vault -n vault -o jsonpath='{.data.token}' | base64 --decode >apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster/token_reviewr_jwt
  if [ $? -eq 0 ]; then
    log_success "Kubernetes token retrieved successfully!"
  else
    log_error "Failed to retrieve Kubernetes token. Please check the logs."
    return 1
  fi

  K8S_HOST=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
  printf 'kubernetes_host = "%s"\n' "$K8S_HOST" >apps/hashicorp-vault/CaC/vault/terraform.tfvars
  log_success "Kubernetes host configured successfully!"

  log_info "Generate CA Certificate for PKI"
  source scripts/generate_root_ca.sh
  generate_ca 90 "TestBox Root CA"

  log_info "Configuring HashiCorp Vault with Terraform..."
  export VAULT_ADDR=http://vault.testbox.pod
  export VAULT_TOKEN=root

  cd apps/hashicorp-vault/CaC/vault/
  terraform init
  if [ $? -eq 0 ]; then
    log_success "Terraform initialized successfully!"
  else
    log_error "Terraform initialization failed. Please check the logs."
    return 1
  fi

  terraform apply --auto-approve
  if [ $? -eq 0 ]; then
    log_success "Terraform applied successfully!"
  else
    log_error "Terraform apply failed. Please check the logs."
    return 1
  fi
  cd -

  log_success "HashiCorp Vault setup completed successfully!"
}
