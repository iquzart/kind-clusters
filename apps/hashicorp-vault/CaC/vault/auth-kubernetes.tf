#----------------------------------------------------------
# Enable Kubernetes Auth Method
#----------------------------------------------------------

# kind_cluster
resource "vault_auth_backend" "kind_cluster" {
 type = "kubernetes"
 path = "kubernetes/kind_cluster"
}

resource "vault_kubernetes_auth_backend_config" "kind_cluster" {
 backend                = vault_auth_backend.kind_cluster.path
 kubernetes_host        = var.kubernetes_host
 kubernetes_ca_cert     = file("kubernetes/kind_cluster/ca.pem")
 token_reviewer_jwt     = file("kubernetes/kind_cluster/token_reviewr_jwt")
 issuer                 = "https://kubernetes.default.svc.cluster.local"
}

resource "vault_kubernetes_auth_backend_role" "kind_cluster_role_go_app" {
 backend                          = vault_auth_backend.kind_cluster.path
 role_name                        = "go-app"
 bound_service_account_names      = ["*"]
 bound_service_account_namespaces = ["*"]
 token_ttl                        = 3600
 token_policies                   = ["dev-ro"]
}
