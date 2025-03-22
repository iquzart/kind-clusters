#----------------------------------------------------------
# Enable Kubernetes Auth Method
#----------------------------------------------------------

# devops_cluster
resource "vault_auth_backend" "devops_cluster" {
 type = "kubernetes"
 path = "kubernetes/devops_cluster"
}

resource "vault_kubernetes_auth_backend_config" "devops_cluster" {
 backend                = vault_auth_backend.devops_cluster.path
 kubernetes_host        = var.kubernetes_host
 kubernetes_ca_cert     = file("kubernetes/devops_cluster/ca.pem")
 token_reviewer_jwt     = file("kubernetes/devops_cluster/token_reviewr_jwt")
 issuer                 = "https://kubernetes.default.svc.cluster.local"
 disable_iss_validation = "true"
}

resource "vault_kubernetes_auth_backend_role" "devops_cluster_role_go_app" {
 backend                          = vault_auth_backend.devops_cluster.path
 role_name                        = "go-app"
 bound_service_account_names      = ["*"]
 bound_service_account_namespaces = ["*"]
 token_ttl                        = 3600
 token_policies                   = ["dev-ro"]
}
