#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Validation
validate_input() {
  local input=$1
  local pattern=$2
  [[ "$input" =~ $pattern ]] || {
    log_error "Invalid input"
    return 1
  }
}

check_dependencies() {
  local deps=("kind" "kubectl" "helm" "yq" "jq")
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing dependencies: ${missing[*]}"
    return 1
  fi
}

invalid_option() {
  log_error "Invalid option, please try again"
  sleep 1
}

check_port() {
  local port=$1

  if command -v ss &>/dev/null; then
    # Linux preferred (ss is faster and more modern)
    if ss -tuln | grep -q ":$port "; then
      log_error "Port $port is in use."
      exit 1
    fi
  elif command -v lsof &>/dev/null; then
    # Fallback for macOS
    if lsof -iTCP:"$port" -sTCP:LISTEN -n >/dev/null; then
      log_error "Port $port is in use."
      exit 1
    fi
  else
    log_warning "Neither ss nor lsof is available on this system."
    exit 1
  fi
}
