#---------------------
# Create policies
#---------------------

# Create vault-admins policy
resource "vault_policy" "admin_policy" {
  name   = "vault-admins"
  policy = file("policies/vault-admin-policy.hcl")
}

resource "vault_policy" "vault_super_admin_policy" {
  name   = "vault-super-admin"
  policy = file("policies/vault-super-admin-policy.hcl")
}

# Create 'snapshot' policy
resource "vault_policy" "snapshot_policy" {
  name   = "snapshot"
  policy = file("policies/snapshot.hcl")
}

#---------------------
# development policies
#---------------------

# Create dev admin policy
resource "vault_policy" "dev-admin" {
  name   = "dev-admin"
  policy = file("policies/dev/dev-admin.hcl")
}

# Create dev read-only policy
resource "vault_policy" "dev-ro" {
  name   = "dev-ro"
  policy = file("policies/dev/dev-ro.hcl")
}

# Create uat admin policy
resource "vault_policy" "uat-admin" {
  name   = "uat-admin"
  policy = file("policies/uat/uat-admin.hcl")
}

# Create uat read-only policy
resource "vault_policy" "uat-ro" {
  name   = "uat-ro"
  policy = file("policies/uat/uat-ro.hcl")
}

# Create qa admin policy
resource "vault_policy" "qa-admin" {
  name   = "qa-admin"
  policy = file("policies/qa/qa-admin.hcl")
}

# Create qa read-only policy
resource "vault_policy" "qa-ro" {
  name   = "qa-ro"
  policy = file("policies/qa/qa-ro.hcl")
}