#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"

tempo_run_checks() {
  local failed=0

  # 1️⃣ Service Check
  status="$(systemctl is-active "$TEMPO_SERVICE" 2>/dev/null || echo "unknown")"

  if [[ "$status" != "active" ]]; then
    echo "Tempo: service NOT active ($status)"
    failed=1
  fi

  # 2️⃣ RPC Check
  if ! curl -sS "$TEMPO_RPC/status" >/dev/null 2>&1; then
    echo "Tempo: RPC unreachable"
    failed=1
  fi

  return $failed
}