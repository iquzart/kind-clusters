function install_envoy_gateway() {
  echo "Starting Envoy gateway installation..."

  # TODO: pin --version <x.y.z> for reproducibility
  helm install eg oci://docker.io/envoyproxy/gateway-helm \
    -n envoy-gateway-system --create-namespace

  echo "Waiting for Envoy gateway to be in the Running state..."
  if ! kubectl -n envoy-gateway-system wait \
    --for=condition=ready pod \
    -l app.kubernetes.io/name=gateway-helm \
    --timeout=600s; then
    echo "Envoy gateway installation failed or timed out."
    exit 1
  fi

  echo "Setting up proxy config..."
  kubectl apply -f apps/envoy-gateway/manifests/01-proxy-config.yaml

  echo "Setting up gatewayclass..."
  kubectl apply -f apps/envoy-gateway/manifests/02-gatewayclass.yaml

  echo "Envoy gateway is fully installed and running."
}
