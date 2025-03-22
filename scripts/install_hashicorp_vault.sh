function install_hashicorp_vault() {
  echo "🌟 Starting HashiCorp Vault installation..."


  echo "🚀 Installing HashiCorp Vault with Helm..."

  if ! helm repo list | grep -q "hashicorp"; then
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update
  else
    echo "✅ HashiCorp repository already exists. Skipping add."
  fi

  helm upgrade -i kind-vault -n vault --create-namespace \
    --atomic -f apps/hashicorp-vault/deploy/values-kind-vault.yaml apps/hashicorp-vault/deploy/vault-helm-0.22.1 

  if [ $? -eq 0 ]; then
    echo "✅ Vault installation was successful!"
  else
    echo "❌ Vault installation failed. Please check the logs."
    return 1
  fi

  echo "🧹 Cleaning up previous configurations..."
  rm -rf apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster
  mkdir -p apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster

  echo "🔑 Retrieving Kubernetes certificate and token..."
  kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster/ca.pem
  if [ $? -eq 0 ]; then
    echo "✅ Kubernetes certificate retrieved successfully!"
  else
    echo "❌ Failed to retrieve Kubernetes certificate. Please check the logs."
    return 1
  fi

  kubectl get secret kind-vault -n vault -o jsonpath='{.data.token}' | base64 --decode > apps/hashicorp-vault/CaC/vault/kubernetes/devops_cluster/token_reviewr_jwt
  if [ $? -eq 0 ]; then
    echo "✅ Kubernetes token retrieved successfully!"
  else
    echo "❌ Failed to retrieve Kubernetes token. Please check the logs."
    return 1
  fi

  K8S_HOST=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
  printf 'kubernetes_host = "%s"\n' "$K8S_HOST" > apps/hashicorp-vault/CaC/vault/terraform.tfvars
  echo "🌐 Kubernetes host configured successfully!"

  echo "🔧 Configuring HashiCorp Vault with Terraform..."
  export VAULT_ADDR=http://vault.testbox.pod
  export VAULT_TOKEN=root

  cd apps/hashicorp-vault/CaC/vault/
  terraform init
  if [ $? -eq 0 ]; then
    echo "✅ Terraform initialized successfully!"
  else
    echo "❌ Terraform initialization failed. Please check the logs."
    return 1
  fi

  terraform apply --auto-approve
  if [ $? -eq 0 ]; then
    echo "✅ Terraform applied successfully!"
  else
    echo "❌ Terraform apply failed. Please check the logs."
    return 1
  fi
  cd -

  echo "🎉 HashiCorp Vault setup completed successfully!"
}

