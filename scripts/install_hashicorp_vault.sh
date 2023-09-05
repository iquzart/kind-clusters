function install_hashicorp_vault() {
  echo "Setting up HashiCorp Vault"
  helm upgrade -i kind-vault -n vault --create-namespace \
  --atomic -f apps/hashicorp-vault/deploy/values-kind-vault.yaml apps/hashicorp-vault/deploy/vault-helm-0.22.1

  echo "wait for vault service become ready"
  sleep 20

  kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="kind-devops-cluster")].cluster.certificate-authority-data}' | base64 --decode > apps/hashicorp-vault/CaC/vault/kubernetes/kind_cluster/ca.pem

  kubectl get secret kind-vault -n vault -o jsonpath='{.data.token}' |  base64 --decode > apps/hashicorp-vault/CaC/vault/kubernetes/kind_cluster/token_reviewr_jwt

  K8S_HOST=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="kind-devops-cluster")].cluster.server}')

  CONTAINER_NAME="devops-cluster-control-plane"
  K8S_API_ADDRESS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_NAME):6443
  printf 'kubernetes_host = "%s"\n' "$K8S_API_ADDRESS" > apps/hashicorp-vault/CaC/vault/terraform.tfvars

  echo "Configuring HashiCorp Vault"

  export VAULT_ADDR=http://vault.testbox.pod
  export VAULT_TOKEN=root

  cd apps/hashicorp-vault/CaC/vault/
  terraform init
  terraform apply --auto-approve
  cd -
}