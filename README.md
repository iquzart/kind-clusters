# Kind Clusters

Kubernetes - Kind cluster for local DEV/Tests

## bootstrap-devops-cluster.sh
Creates devops-cluster and select one or multiple applications to set up from the following list:
```
1. Nginx Ingress Controller
2. Kube Prometheus Stack
3. HashiCorp Vault
4. Tekton Pipelines with UI
```

## tear-down-cluster.sh
delete one or all the kind clusters identified on your system.

### Pre-Requirements
```
1. Kind
2. Docker
3. Helm
4. kubectl
5. terraform
```