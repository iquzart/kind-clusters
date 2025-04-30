install_nginx_ingress() {
  log_info "Setting up Nginx Ingress controller"
  if kubectl apply -f apps/nginx-ingress/deployment.yaml; then
    log_success "Nginx Ingress controller applied successfully."
  else
    log_error "Failed to apply Nginx Ingress controller."
    return 1
  fi

  # Wait for the ingress-nginx-controller deployment to become ready
  log_info "Waiting for Nginx Ingress Controller pod to become ready"
  if kubectl wait -n ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=200s; then
    log_success "Nginx Ingress Controller pod is ready."
  else
    log_error "Timed out waiting for Nginx Ingress Controller pod to be ready."
    return 1
  fi
}
