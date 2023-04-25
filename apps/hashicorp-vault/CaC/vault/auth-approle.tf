#----------------------------------------------------------
# Enable AppRole Auth Method
#----------------------------------------------------------
resource "vault_auth_backend" "approle" {
  type = "approle"
  path = "approle/snapshot"
}


# Create snaphot_agent role
resource "vault_approle_auth_backend_role" "snapshot_agent" {
  backend         = vault_auth_backend.approle.path
  role_name       = "snapshot-agent"
  token_policies  = ["snapshot"]
  token_ttl       = "900"
}