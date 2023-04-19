function install_kube_prometheus_stack() {
  echo "Setting up Kube-prometheus stack"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  helm upgrade --install kind-monitor \
    prometheus-community/kube-prometheus-stack \
    --namespace observability --create-namespace --atomic -f apps/observability/kube-prometheus-stack/values.yaml
  echo "Configuring Prometheus to scrap Nginx Metrics"
  kubectl apply -f apps/nginx-ingress/monitor.yaml
}