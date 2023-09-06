#--------------------------------
# Setup PKI Secret Engine
#--------------------------------

# ROOT CA
resource "vault_mount" "pki" {
  path        = var.pki_ca_path
  type        = "pki"
  description = var.pki_ca_description

  default_lease_ttl_seconds = var.pki_ca_default_lease_ttl_seconds
  max_lease_ttl_seconds     = var.pki_ca_max_lease_ttl_seconds
}

resource "vault_pki_secret_backend_root_cert" "root_ca" {
  backend     = vault_mount.pki.path
  type        = var.pki_ca_root_cert_type
  common_name = var.pki_ca_common_name
  ttl         = var.pki_ca_root_cert_ttl
  issuer_name = var.pki_ca_issuer_name
}

resource "vault_pki_secret_backend_issuer" "root_ca" {
  backend                        = vault_mount.pki.path
  issuer_ref                     = vault_pki_secret_backend_root_cert.root_ca.issuer_id
  issuer_name                    = vault_pki_secret_backend_root_cert.root_ca.issuer_name
  revocation_signature_algorithm = var.pki_ca_issuer_revocation_signature_algorithm
}

resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_mount.pki.path
  name             = var.pki_ca_role_name
  ttl              = var.pki_ca_role_ttl
  allow_ip_sans    = var.pki_ca_role_allow_ip_sans
  key_type         = var.pki_ca_role_key_type
  key_bits         = var.pki_ca_role_key_bits
  allowed_domains  = var.pki_ca_role_allowed_domains
  allow_subdomains = var.pki_ca_role_allow_subdomains
  allow_any_name   = var.pki_ca_role_allow_any_name
}

resource "vault_pki_secret_backend_config_urls" "config-urls" {
  backend = vault_mount.pki.path
  issuing_certificates    = var.pki_ca_config_issuing_certificates
  crl_distribution_points = var.pki_ca_config_crl_distribution_points
}


# Intermediate CA
resource "vault_mount" "pki_int" {
  path        = var.pki_int_path
  type        = "pki"
  description = var.pki_int_description

  default_lease_ttl_seconds = var.pki_int_default_lease_ttl_seconds
  max_lease_ttl_seconds     = var.pki_int_max_lease_ttl_seconds
}

resource "vault_pki_secret_backend_intermediate_cert_request" "csr-request" {
  backend     = vault_mount.pki_int.path
  type        = "internal"
  common_name = var.pki_int_common_name
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend     = vault_mount.pki.path
  common_name = var.pki_int_root_sign_common_name
  csr         = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr
  format      = var.pki_int_root_sign_format
  ttl         = var.pki_int_root_sign_ttl
  issuer_ref  = vault_pki_secret_backend_root_cert.root_ca.issuer_id
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

resource "vault_pki_secret_backend_issuer" "intermediate" {
  backend     = vault_mount.pki_int.path
  issuer_ref  = vault_pki_secret_backend_intermediate_set_signed.intermediate.imported_issuers[0]
  issuer_name = var.pki_int_issuer_name
}

resource "vault_pki_secret_backend_role" "intermediate_role" {
  backend          = vault_mount.pki_int.path
  issuer_ref       = vault_pki_secret_backend_issuer.intermediate.issuer_ref
  name             = var.pki_int_role_name
  ttl              = var.pki_int_role_ttl
  max_ttl          = var.pki_int_role_max_ttl
  allow_ip_sans    = true
  key_type         = var.pki_int_role_key_type
  key_bits         = var.pki_int_role_key_bits
  require_cn       = false
  allowed_domains  = var.pki_int_role_allowed_domains
  allow_subdomains = var.pki_int_role_allow_subdomains
}

# resource "vault_pki_secret_backend_cert" "example-dot-com" {
#   issuer_ref  = vault_pki_secret_backend_issuer.intermediate.issuer_ref
#   backend     = vault_pki_secret_backend_role.intermediate_role.backend
#   name        = vault_pki_secret_backend_role.intermediate_role.name
#   common_name = var.pki_int_cert_common_name
#   ttl         = var.pki_int_cert_ttl
#   revoke     = true
# }
