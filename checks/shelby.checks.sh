#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"

shelby_run_checks() {
  local failed=0

  # 1️⃣ Service Check
  status="$(systemctl is-active "$SHELBY_SERVICE" 2>/dev/null || echo "unknown")"

  if [[ "$status" != "active" ]]; then
    echo "Shelby: service NOT active ($status)"
    failed=1
  fi

  # 2️⃣ RPC Check
  if ! curl -sS "$SHELBY_RPC/status" >/dev/null 2>&1; then
    echo "Shelby: RPC unreachable"
    failed=1
  fi

  return $failed
}