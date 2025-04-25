function install_cilium_cni() {
  echo "Starting Cilium CNI installation..."

  helm repo add cilium https://helm.cilium.io/

  helm upgrade --install cilium cilium/cilium --version 1.17.3 \
    --namespace cilium-system --create-namespace \
    --set image.pullPolicy=IfNotPresent \
    --set ipam.mode=kubernetes \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true

  echo "Waiting for Cilium pods to be in the Running state..."

  kubectl -n cilium-system wait --for=condition=ready pod -l k8s-app=cilium --timeout=600s

  if [ $? -eq 0 ]; then
    echo "Cilium is fully installed and running."
  else
    echo "Cilium installation failed or timed out."
    exit 1
  fi
}
