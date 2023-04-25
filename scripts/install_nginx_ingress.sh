function install_nginx_ingress() {
  echo "Setting up Nginx Ingress controller"
  kubectl apply -f apps/nginx-ingress/deployment.yaml

  # Wait for the ingress-nginx-controller deployment to become ready
  echo "Waiting for Nginx Ingress Controller pod become ready"
  kubectl wait -n ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=200s
}