#----------------------------------------------------------
# Enable secrets engines
#----------------------------------------------------------


# Creating kv2 secret engine for dev
resource "vault_mount" "dev" {
  path        = "dev"
  type        = "kv-v2"
  description = "Static secrets for Development environement"
}

resource "vault_kv_secret_v2" "go_app" {
  mount                      = vault_mount.dev.path
  name                       = "go-app"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
    {
      BANNER       = "Secret From Kind Vault"
    }
  )
}

# Creating kv2 secret engine for UAT
resource "vault_mount" "uat" {
  path        = "uat"
  type        = "kv-v2"
  description = "Static secrets for UAT environement"
}

# Creating kv2 secret engine for UAT
resource "vault_mount" "qa" {
  path        = "qa"
  type        = "kv-v2"
  description = "Static secrets for QA environement"
}



