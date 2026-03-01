#!/usr/bin/env bash
set -euo pipefail

# Usage:
# CONFIG_FILE=./config/common.env ./run/run_all.sh
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/config/common.env}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config not found: $CONFIG_FILE"
  echo "Create it by copying:"
  echo "  cp $ROOT_DIR/config/common.env.example $ROOT_DIR/config/common.env"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1"
    exit 1
  }
}

ts_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }