#!/bin/bash
source ./utilities.sh

should_build_custom_image() {
  yq eval '.custom_image.enabled' config/config.yaml | grep -q 'true'
}

get_custom_image_spec() {
  if should_build_custom_image; then
    echo "$(yq eval '.custom_image.custom_image' config/config.yaml)"
  else
    echo ""
  fi
}

get_default_image() {
  local cluster_type=$1
  local version=$(yq eval ".cluster_types.$cluster_type.version" config/config.yaml)
  echo "kindest/node:v${version}"
}

get_cluster_image() {
  local cluster_type=$1
  local custom_image=$(get_custom_image_spec)

  if [[ -n "$custom_image" ]]; then
    echo "$custom_image"
  else
    get_default_image "$cluster_type"
  fi
}

build_custom_image_if_needed() {
  if ! should_build_custom_image; then
    return 0
  fi

  local image_name=$(yq eval '.custom_image.custom_image' config/config.yaml)
  local version=$(yq eval '.custom_image.version' config/config.yaml)
  local ca_cert_path=$(yq eval '.custom_image.ca_certs[0]' config/config.yaml)

  if [[ ! -f "$ca_cert_path" ]]; then
    log_error "CA certificate not found at $ca_cert_path"
    return 1
  fi

  log "Checking for existing custom image ${image_name}..."
  if docker image inspect "$image_name" >/dev/null 2>&1; then
    log_success "Custom image already exists"
    return 0
  fi

  local arch
  arch=$(uname -m)
  local platform

  case "$arch" in
  x86_64) platform="linux/amd64" ;;
  arm64) platform="linux/arm64" ;;
  *) echo "Unsupported architecture: $arch" && exit 1 ;;
  esac

  log "Building ${platform} custom image ${image_name} with corporate CA..."

  if docker build \
    --platform "$platform" \
    --build-arg K8S_VERSION="$version" \
    -t "$image_name" \
    -f "Containerfiles/Containerfile.OrgCa" Containerfiles/; then
    log_success "Built custom image ${image_name}"
  else
    log_error "Failed to build custom image ${image_name}"
    return 1
  fi
}
