function generate_ca() {
  set -e

  VALIDITY_DAYS=${1:-365}
  COMMON_NAME=${2:-"TestBox Root CA v1"}
  ORGANIZATION=${3:-"TestBox Org"}
  CA_CERT_PATH="apps/hashicorp-vault/certificates/ca"

  CERT_FILE="${CA_CERT_PATH}/root-ca-v1.crt"
  KEY_FILE="${CA_CERT_PATH}/root-ca-key-v1.key"
  CRL_FILE="${CA_CERT_PATH}/root-ca-v1.crl"
  INDEX_FILE="${CA_CERT_PATH}/index.txt"
  CRL_NUMBER_FILE="${CA_CERT_PATH}/crlnumber"
  NEW_CERTS_DIR="${CA_CERT_PATH}/newcerts"

  # Create necessary directories and files
  mkdir -p "$CA_CERT_PATH"
  mkdir -p "$NEW_CERTS_DIR"

  # Initialize index.txt and crlnumber file if they don't exist
  if [[ ! -f "$INDEX_FILE" ]]; then
    touch "$INDEX_FILE"
    log_info "Created index.txt file."
  fi
  if [[ ! -f "$CRL_NUMBER_FILE" ]]; then
    echo 1000 >"$CRL_NUMBER_FILE"
    log_info "Created crlnumber file."
  fi

  # Log start of Root CA generation process
  log_info "Starting Root CA generation process..."

  if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
    log_success "Existing certificate and key found. Checking validity..."

    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)

    # Convert to timestamp based on OS
    if date -d "$EXPIRY_DATE" +%s >/dev/null 2>&1; then
      EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
    else
      EXPIRY_TIMESTAMP=$(date -j -f "%b %e %T %Y %Z" "$EXPIRY_DATE" "+%s")
    fi

    NOW_TIMESTAMP=$(date +%s)
    ONE_DAY_SECONDS=86400

    if ((EXPIRY_TIMESTAMP > (NOW_TIMESTAMP + ONE_DAY_SECONDS))); then
      log_success "Certificate is still valid for more than 1 day. Skipping regeneration."
      return
    else
      log_warn "Certificate is expired or expiring soon. Regenerating..."
    fi
  else
    log_warn "Certificate or key file not found. Generating new Root CA..."
  fi

  log_info "Generating Root CA key..."
  openssl genrsa -out "$KEY_FILE" 4096

  log_info "Generating Root CA certificate..."
  openssl req -x509 -new -nodes -key "$KEY_FILE" -sha256 -days "$VALIDITY_DAYS" \
    -out "$CERT_FILE" -subj "/O=$ORGANIZATION/CN=$COMMON_NAME"

  log_info "Generating CRL file..."
  openssl ca -gencrl -keyfile "$KEY_FILE" -cert "$CERT_FILE" -out "$CRL_FILE" \
    -config <(
      cat <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = .
database          = $CA_CERT_PATH/index.txt
new_certs_dir     = $CA_CERT_PATH/newcerts
certificate       = $CERT_FILE
private_key       = $KEY_FILE
default_crl_days  = $VALIDITY_DAYS
crlnumber         = $CA_CERT_PATH/crlnumber
crl               = $CRL_FILE
default_md        = sha256
EOF
    )

  log_success "Root CA generation complete:"
  log_info " - Certificate: $CERT_FILE"
  log_info " - Key:         $KEY_FILE"
  log_info " - CRL:         $CRL_FILE"
}
