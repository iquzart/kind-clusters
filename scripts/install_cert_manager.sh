function install_cert_manager() {
  echo "Setting up Cert Manager"

  helm repo add jetstack https://charts.jetstack.io
  helm repo update

  helm upgrade --install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.12.0 \
    --set installCRDs=true \
    --set prometheus.enabled=false \
    --set webhook.timeoutSeconds=4 \
    --atomic
}