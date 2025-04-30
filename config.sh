#!/bin/bash

readonly KIND_IMAGE="kindest/node"
readonly KIND_CUSTOM_IMAGE_TAG="with-org-ca"
readonly K8S_VERSION="v1.32.2"

# Tokyonight Theme Colors
readonly MAGENTA="\033[1;35m"
readonly BLUE="\033[1;34m"
readonly GREEN="\033[1;32m"
readonly RED="\033[1;31m"
readonly YELLOW="\033[1;33m"
readonly RESET="\033[0m"

log_info() { echo -e "\033[34m[INFO]\033[0m $*"; }
log_success() { echo -e "\033[32m[✓]\033[0m $*"; }
log_warn() { echo -e "\033[33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[31m[✗]\033[0m $*" >&2; }

export -f log_info log_success log_warn log_error
