function install_tekton() {
  echo "Setting up Tekton"
  kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml

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
