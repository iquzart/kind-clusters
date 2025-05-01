resource "vault_mount" "pki_iss" {
  path                  = var.pki_iss_mount_path
  type                  = "pki"
  description           = "PKI engine hosting issuing CA"
  max_lease_ttl_seconds = local.duration_1y_in_sec
}

resource "vault_pki_secret_backend_config_issuers" "iss" {
  count   = var.iss_default_issuer != null ? 1 : 0
  backend = vault_mount.pki_iss.path
  default = var.iss_default_issuer
}

resource "vault_pki_secret_backend_role" "testbox_pod" {
  backend                     = vault_mount.pki_iss.path
  name                        = "testbox_pod"
  organization                = [var.organization]
  key_type                    = var.default_key_type
  key_bits                    = var.default_key_bits
  max_ttl                     = local.duration_1hr_in_sec
  allowed_domains             = ["testbox.pod"]
  allow_subdomains            = true
  allow_ip_sans               = true
  allow_wildcard_certificates = false
  issuer_ref                  = "default"
}
