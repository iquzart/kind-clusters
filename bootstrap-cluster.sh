#!/bin/bash

# Define functions

function prompt_for_cluster_name() {
  read -p "Enter the name of the Kind cluster: " CLUSTER_NAME
}

function prompt_for_applications() {
  echo "Which applications would you like to install? (separate with commas, or leave blank for none)"
  echo "1. Nginx Ingress Controller"
  echo "2. Kube-prometheus stack"
  echo "3. HashiCorp Vault"
  echo "4. Tekton"
  read -p "Enter your selection(s): " SELECTIONS
}

function create_kind_cluster() {
  echo "Creating Kind cluster $CLUSTER_NAME"
  envsubst < cluster-configs/basic-cluster.yaml | kind create cluster --name $CLUSTER_NAME --config=-
}

function install_nginx_ingress() {
  echo "Setting up Nginx Ingress controller"
  kubectl apply -f apps/nginx-ingress/deployment.yaml

  # Wait for the ingress-nginx-controller deployment to become ready
  echo "Waiting for Nginx Ingress Controller pod become ready"
  kubectl wait -n ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s
}

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

function install_hashicorp_vault() {
  echo "Setting up HashiCorp Vault"
  # TODO: Add installation steps here
}

function install_tekton() {
  echo "Setting up Tekton"
  kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

  kubectl wait -n tekton-pipelines \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/part-of=tekton-pipelines,app.kubernetes.io/component=controller \
    --timeout=90s

  curl -sL https://raw.githubusercontent.com/tektoncd/dashboard/main/scripts/release-installer | \
    bash -s -- install latest --read-write --ingress-url tekton-dashboard.testbox.pod

  kubectl wait -n tekton-pipelines \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/part-of=tekton-dashboard,app.kubernetes.io/component=dashboard \
    --timeout=90s
}

# Main script

prompt_for_cluster_name
prompt_for_applications
create_kind_cluster

if [[ ! -z "$SELECTIONS" ]]; then
  for SELECTION in $(echo $SELECTIONS | tr ',' '\n'); do
    case $SELECTION in
      1)
        install_nginx_ingress
        ;;
      2)
        install_kube_prometheus_stack
        ;;
      3)
        install_hashicorp_vault
        ;;
      4)
        install_tekton
        ;;
      *)
        echo "Invalid selection: $SELECTION"
        ;;
    esac
  done
else
  echo "No applications selected"
fi
