function install_trivy_operator() {
  echo "Setting up Trivy Operator"

  helm repo add aqua https://aquasecurity.github.io/helm-charts/
  helm repo update

  helm upgrade --install trivy-operator aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --atomic \
    -f apps/trivy-operator/values-kind.yaml
}
