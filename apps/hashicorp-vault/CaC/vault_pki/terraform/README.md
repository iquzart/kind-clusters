# Create pki_int - PKI Engine

CA_CERT_PATH="apps/hashicorp-vault/certificates/ca"

terraform init

terraform plan -target vault_pki_secret_backend_config_issuers.int

terraform apply -auto-approve \
-target vault_pki_secret_backend_config_issuers.int

terraform plan -target module.issuer_v1_1

terraform apply -auto-approve -target module.issuer_v1_1

terraform output -json > pki_int_v1.1.json
jq -r .csr_v1_1.value pki_int_v1.1.json > ../../../certificates/ca/pki_int_v1.1.csr

cat > apps/hashicorp-vault/certificates/ca/intermediate.ext <<EOF
[v3_ca]
basicConstraints = critical,CA:true,pathlen:1
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

echo '1000' > apps/hashicorp-vault/certificates/ca/root-ca-v1.srl

CA_CERT_PATH="apps/hashicorp-vault/certificates/ca"
openssl x509 -req \
 -in ${CA_CERT_PATH}/pki_int_v1.1.csr \
  -CA "${CA_CERT_PATH}/root-ca-v1.crt" \
 -CAkey "${CA_CERT_PATH}/root-ca-key-v1.key" \
  -CAserial "${CA_CERT_PATH}/root-ca-v1.srl" \
 -out ${CA_CERT_PATH}/pki_int_v1.1.crt \
  -days 180 \
  -sha256 \
  -extfile "${CA_CERT_PATH}/intermediate.ext" \
 -extensions v3_ca

openssl x509 -in ${CA_CERT_PATH}/pki_int_v1.1.crt -text -noout

cp ${CA_CERT_PATH}/pki_int_v1.1.crt apps/hashicorp-vault/CaC/vault_pki/terraform

# once the certificate is ready

terraform apply -auto-approve \
 -target module.issuer_v1_1

terraform output -json > pki_int_v1.1.json
jq -r .csr_v1_1.value pki_int_v1.1.json > pki_int_v1.1.issuer

# ISS

terraform apply -auto-approve \
 -target module.issuer_v1_1_1

terraform output -json > pki_iss_v1.1.1.json

jq -r .certificate_v1_1_1.value pki_iss_v1.1.1.json > pki_iss_v1.1.1.crt
jq -r .issuer_v1_1_1.value pki_iss_v1.1.1.json > pki_iss_v1.1.1.issuer
openssl x509 -in pki_iss_v1.1.1.crt -text -noout

terraform apply -auto-approve \
 -target vault_pki_secret_backend_role.testbox_pod
