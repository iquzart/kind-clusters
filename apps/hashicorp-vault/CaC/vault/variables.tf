variable "kubernetes_host" {
  type    = string
  default = "https://kubernetes.default.svc"
}


# PKI Engine Variables
#======================#
# CA
variable "pki_ca_path" {
  description = "Path for the PKI mount"
  default     = "pki_root_ca"
}

variable "pki_ca_description" {
  description = "Description for the PKI mount"
  default     = "Root CA"
}

variable "pki_ca_default_lease_ttl_seconds" {
  description = "Default lease TTL in seconds for the PKI mount"
  default     = 86400
}

variable "pki_ca_max_lease_ttl_seconds" {
  description = "Max lease TTL in seconds for the PKI mount"
  default     = 315360000
}


variable "pki_ca_common_name" {
  description = "Common name for the PKI CA"
  default = "testbox.pod"
}

variable "pki_ca_issuer_name" {
  description = "Issuer name for the PKI CA"
  default = "kind-cluster"
}

variable "pki_ca_root_cert_type" {
  description = "Type for the PKI root certificate"
  default     = "internal"
}

variable "pki_ca_root_cert_ttl" {
  description = "TTL for the PKI root certificate"
  default     = 315360000
}

variable "pki_ca_issuer_revocation_signature_algorithm" {
  description = "Revocation signature algorithm for the PKI issuer"
  default     = "SHA256WithRSA"
}

variable "pki_ca_role_name" {
  description = "Name for the PKI role"
  default     = "kind-cluster"
}

variable "pki_ca_role_ttl" {
  description = "TTL for the PKI role"
  default     = 86400
}

variable "pki_ca_role_allowed_domains" {
  description = "Allowed domains for the PKI role"
  default     = ["testbox.pod", "testbox.vm"]
}

variable "pki_ca_role_key_type" {
  description = "Key type for the PKI role"
  default     = "rsa"
}

variable "pki_ca_role_key_bits" {
  description = "Key bits for the PKI role"
  default     = 2048
}

variable "pki_ca_role_allow_ip_sans" {
  description = "Allow IP SANs for the PKI role"
  default     = true
}

variable "pki_ca_role_allow_subdomains" {
  description = "Allow subdomains for the PKI role"
  default     = true
}

variable "pki_ca_role_allow_any_name" {
  description = "Allow any name for the PKI role"
  default     = true
}

variable "pki_ca_config_issuing_certificates" {
  description = "Issuing certificates URL for PKI configuration"
  default     = ["http://vault.testbox.pod/v1/pki/ca"]
}

variable "pki_ca_config_crl_distribution_points" {
  description = "CRL distribution points URL for PKI configuration"
  default     = ["http://vault.testbox.pod/v1/pki/crl"]
}

# Intermediate CA
variable "pki_int_path" {
  description = "Path for the intermediate PKI mount"
  default     = "pki_intermediate_ca"
}

variable "pki_int_description" {
  description = "Description for the intermediate PKI mount"
  default     = "Intermediate CA"
}

variable "pki_int_default_lease_ttl_seconds" {
  description = "Default lease TTL in seconds for the intermediate PKI mount"
  default     = 86400
}

variable "pki_int_max_lease_ttl_seconds" {
  description = "Max lease TTL in seconds for the intermediate PKI mount"
  default     = 157680000
}

variable "pki_int_common_name" {
  description = "Common name for the intermediate PKI"
  default     = "testbox.pod Intermediate Authority"
}

variable "pki_int_root_sign_common_name" {
  description = "Common name for the root-signed intermediate PKI"
  default     = "kind-cluster-intermediate"
}

variable "pki_int_root_sign_format" {
  description = "Format for the root-signed intermediate PKI"
  default     = "pem_bundle"
}

variable "pki_int_root_sign_ttl" {
  description = "TTL for the root-signed intermediate PKI"
  default     = 15480000
}

variable "pki_int_issuer_name" {
  description = "Issuer name for the intermediate PKI"
  default     = "testbox-dot-pod-intermediate"
}

variable "pki_int_role_name" {
  description = "Name for the intermediate PKI role"
  default     = "testbox-dot-pod"
}

variable "pki_int_role_ttl" {
  description = "TTL for the intermediate PKI role"
  default     = 86400
}

variable "pki_int_role_max_ttl" {
  description = "Max TTL for the intermediate PKI role"
  default     = 2592000
}

variable "pki_int_role_key_type" {
  description = "Key type for the intermediate PKI role"
  default     = "rsa"  # or specify your preferred default value
}

variable "pki_int_role_key_bits" {
  description = "Key bits for the intermediate PKI role"
  default     = 2048  # or specify your preferred default value
}

variable "pki_int_role_allowed_domains" {
  description = "Allowed domains for the intermediate PKI role"
  default     = ["testbox.pod"]
}

variable "pki_int_role_allow_subdomains" {
  description = "Allow subdomains for the intermediate PKI role"
  default     = true
}

# variable "pki_int_cert_common_name" {
#   description = "Common name for the intermediate certificate"
#   default     = "go-app.testbox.pod"
# }

# variable "pki_int_cert_ttl" {
#   description = "TTL for the intermediate certificate"
#   default     = 3600
# }
